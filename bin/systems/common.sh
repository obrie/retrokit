#!/bin/bash

##############
# Common functions used across system installs
##############

export DIR=$(dirname "$0")
export APP_DIR=$(cd "$DIR/../.." && pwd)
export APP_SETTINGS_FILE="$APP_DIR/config/settings.json"
export DATA_DIR="$APP_DIR/data"
export TMP_DIR="$APP_DIR/tmp"

scrape_system() {
  # Arguments
  system="$1"

  # Kill emulation station
  killall /opt/retropie/supplementary/emulationstation/emulationstation

  # Scrape
  /opt/retropie/supplementary/skyscraper/Skyscraper -p "$system" -g "/home/pi/.emulationstation/gamelists/$system" -o "/home/pi/.emulationstation/downloaded_media/$system" -s screenscraper --flags "unattend,skipped,videos"

  # Generate game list
  /opt/retropie/supplementary/skyscraper/Skyscraper -p "$system" -g "/home/pi/.emulationstation/gamelists/$system" -o "/home/pi/.emulationstation/downloaded_media/$system" --flags "unattend,skipped,videos"
}

setup_system() {
  # Arguments
  system="$1"

  # Configuration
  system_config_dir="$APP_DIR/config/systems/$system"
  system_settings_file="$system_config_dir/settings.json"

  if [ $(jq -r 'has("emulators")' "$system_settings_file") = "true" ]; then
    jq -r '.emulators[]' "$system_settings_file" | while read emulator; do
      # Retroarch
      retropie_configs_dir="/opt/retropie/configs/all"
      emulator_config_dir="$retropie_configs_dir/retroarch/config/$emulator"
      mkdir -p "$emulator_config_dir"

      # Core Options overides (https://retropie.org.uk/docs/RetroArch-Core-Options/)
      find "$system_config_dir/retroarch_opts" -iname "*.opt" | while read override_file; do
        opt_name=$(basename "$override_file")
        opt_file="$emulator_config_dir/$opt_name"
        touch "$opt_file"
        crudini --merge --output="$opt_file" "$retropie_configs_dir/retroarch-core-options.cfg" < "$override_file"
      done
    done
  fi
}

download_file() {
  # Arguments
  url="$1"
  output="$2"

  if [ ! -f "$output" ]; then
    if [[ "$url" == *"https://archive.org/download/"* ]]; then
      # Need to make sure we use the `ia` command-line
      item=$(echo "$url" | grep -oP "download/\K[^/]+")
      file=$(echo "$url" | grep -oP "$item/\K.+$")
      ia download "$item" "$file" -s > "$output"
    else
      wget "$url" -O "$output"
    fi
  fi
}

# TODO: Smarter file lists
download_source() {
  # Arguments
  system="$1"
  source_name="$2"

  # Configuration
  system_config_dir="$APP_DIR/config/systems/$system"
  system_settings_file="$system_config_dir/settings.json"
  system_tmp_dir="$TMP_DIR/$system"
  mkdir -p "$system_tmp_dir"

  # Source
  source_type=$(jq -r ".sources.$source_name.type" "$APP_SETTINGS_FILE")
  source_url=$(jq -r ".sources.$source_name.url" "$APP_SETTINGS_FILE")
  source_root_dir=$(jq -r ".sources.$source_name.root_dir" "$APP_SETTINGS_FILE")
  source_unzip=$(jq -r ".sources.$source_name.unzip" "$APP_SETTINGS_FILE")

  # Source Filter
  source_filter="$system_tmp_dir/files.filter"
  if [ "$(jq -r ".roms.sources.$source_name | has(\"files\")" "$system_settings_file")" = "true" ]; then
    jq -r "if .roms.sources.$source_name | has(\"files\") then .roms.sources.$source_name.files[] else [] end" "$system_settings_file" > "$source_filter"
    roms_all_dir="/home/pi/RetroPie/roms/$system/-ALL-"
  else
    roms_all_dir="/home/pi/RetroPie/roms/$system"
  fi

  # Target
  mkdir -p "$roms_all_dir"

  if [ "$source_type" = "torrent" ]; then
    # Torrent Info
    torrent_file="$TMP_DIR/$source_name.torrent"

    # Download target
    rom_source_dir="/var/lib/transmission-daemon/downloads/$source_root_dir"

    # Download torrent
    download_file "$source_url" "$torrent_file"
    "$APP_DIR/bin/tools/torrent.sh" "$torrent_file" "$source_filter"
  elif [ "$source_type" = "http" ]; then
    rom_source_dir="$system_tmp_dir/downloads"
    mkdir -p "$rom_source_dir"

    # Download URLs
    cat "$source_filter" | while read file; do
      download_file "$source_url$file" "$rom_source_dir/$file"
    done
  else
    echo "Invalid source type: $source_type"
    exit 1
  fi

  # todo: delete as we unzip
  if [ "$source_unzip" = "true" ]; then
    # Extract files
    unzip -o "$rom_source_dir/*.zip" -d "$roms_all_dir/"
    sudo find "$rom_source_dir" -mindepth 1 -exec rm "{}" \;
  else
    sudo find "$rom_source_dir" -mindepth 1 -exec mv "{}" "$roms_all_dir/" \;
  fi
}

download_system() {
  # Arguments
  system="$1"

  # Configuration
  system_config_dir="$APP_DIR/config/systems/$system"
  system_settings_file="$system_config_dir/settings.json"

  jq -r '.roms.sources | keys[]' "$system_settings_file" | while read source_name; do
    download_source "$system" "$source_name"
  done
}

organize_system() {
  # Arguments
  system="$1"

  # Configuration
  system_config_dir="$APP_DIR/config/systems/$system"
  system_settings_file="$system_config_dir/settings.json"

  # Target
  roms_dir="/home/pi/RetroPie/roms/$system"
  roms_all_dir="$roms_dir/-ALL-"
  roms_blocked_dir="$roms_dir/.blocked"
  roms_duplicates_dir="$roms_dir/.duplicates"
  mkdir -p "$roms_all_dir" "$roms_blocked_dir" "$roms_duplicates_dir"

  # Move everything back into ALL so we can start from scratch
  find "$roms_duplicates_dir" "$roms_blocked_dir" -mindepth 1 -maxdepth 1 -exec mv "{}" "$roms_all_dir" \;

  # Allowlist
  # - Keywords
  if [ $(jq -r '.roms.allowlists | has("keywords")' "$system_settings_file") = "true" ]; then
    keywords=$(jq -r '.roms.allowlists.keywords[]' "$system_settings_file" | sed 's/[][()\.^$?*+]/\\&/g' | paste -sd '|')
    find "$roms_all_dir/" -mindepth 1 -regextype posix-extended ! -regex ".*($keywords).*" -exec mv "{}" "$roms_blocked_dir/" \;
  fi

  # Blocklist
  # - Keywords
  if [ $(jq -r '.roms.blocklists | has("keywords")' "$system_settings_file") = "true" ]; then
    blocklist=$(jq -r '.roms.blocklists.keywords[]' "$system_settings_file" | sed 's/[][()\.^$?*+]/\\&/g' | paste -sd '|')
    find "$roms_all_dir/" -mindepth 1 -regextype posix-extended -regex ".*($blocklist).*" -exec mv "{}" "$roms_blocked_dir/" \;
  fi

  # Remove duplicates
  ls $roms_all_dir | grep -oE "^[^(]+" | sort | uniq -c | grep -oP "^ +[^1 ] +\K.+$" | while read -r game; do
    find "$roms_all_dir" -type f -name "$game \(*" | sort -r | tail -n +2 | xargs -d'\n' -I{} mv "{}" "$roms_duplicates_dir/"
  done

  # Remove existing *links* from root
  find "$roms_dir/" -maxdepth 1 -type l -exec rm "{}" \;

  # Add to root
  jq -r ".roms.root[] // []" "$system_settings_file" | while read rom; do
    # Undo any accidental blocked rom
    if [ -f "$roms_blocked_dir/$rom" ]; then
      mv "$roms_blocked_dir/$rom" "$roms_all_dir/"
    fi

    # Undo any accidental de-duplicated rom
    if [ -f "$roms_duplicates_dir/$rom" ]; then
      mv "$roms_duplicates_dir/$rom" "$roms_all_dir/"
    fi

    ln -fs "$roms_all_dir/$rom" "$roms_dir/$rom"
  done
}
