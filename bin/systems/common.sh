#!/bin/bash

##############
# Common functions used across system installs
##############

# Directories
export dir=$(dirname "$0")
export app_dir=$(cd "$dir/../.." && pwd)
export data_dir="$app_dir/data"
export tmp_dir="$app_dir/tmp"

# Settings
export app_settings_file="$app_dir/config/settings.json"
export sep=$'\t'

# Configurations
export retroarch_cores_config="/opt/retropie/configs/all/retroarch-core-options.cfg"
export es_settings_config="$HOME/.emulationstation/es_systems.cfg"
export es_systems_config="$HOME/.emulationstation/es_systems.cfg"

scrape_system() {
  # Arguments
  local system="$1"
  local source="$2"

  # Kill emulation station
  killall /opt/retropie/supplementary/emulationstation/emulationstation

  # Scrape
  /opt/retropie/supplementary/skyscraper/Skyscraper -p "$system" -s "$source"

  # Generate game list
  /opt/retropie/supplementary/skyscraper/Skyscraper -p "$system"
}

setup_system() {
  # Arguments
  local system="$1"

  # Configuration
  local system_config_dir="$app_dir/config/systems/$system"
  local system_settings_file="$system_config_dir/settings.json"

  if [ $(jq -r 'has("emulators")' "$system_settings_file") = "true" ]; then
    jq -r '.emulators[]' "$system_settings_file" | while read emulator; do
      # Retroarch
      local retropie_configs_dir="/opt/retropie/configs/all"
      local emulator_config_dir="$retropie_configs_dir/retroarch/config/$emulator"
      mkdir -p "$emulator_config_dir"

      # Core Options overides (https://retropie.org.uk/docs/RetroArch-Core-Options/)
      find "$system_config_dir/retroarch_opts" -iname "*.opt" | while read override_file; do
        local opt_name=$(basename "$override_file")
        local opt_file="$emulator_config_dir/$opt_name"
        
        touch "$opt_file"
        crudini --merge --output="$opt_file" "$retropie_configs_dir/retroarch-core-options.cfg" < "$override_file"
      done
    done
  fi
}

download_file() {
  # Arguments
  local url="$1"
  local output="$2"

  if [ ! -f "$output" ]; then
    if [[ "$url" == *"https://archive.org/download/"* ]]; then
      # Need to make sure we use the `ia` command-line
      local item=$(echo "$url" | grep -oP "download/\K[^/]+")
      local file=$(echo "$url" | grep -oP "$item/\K.+$")
      ia download "$item" "$file" -s > "$output"
    else
      wget "$url" -O "$output"
    fi
  fi
}

# TODO: Smarter file lists
download_source() {
  # Arguments
  local system="$1"
  local source_name="$2"

  # Configuration
  local system_config_dir="$app_dir/config/systems/$system"
  local system_settings_file="$system_config_dir/settings.json"
  local system_tmp_dir="$tmp_dir/$system"
  mkdir -p "$system_tmp_dir"

  # Source
  local source_type=$(jq -r ".sources.\"$source_name\".type" "$app_settings_file")
  local source_url=$(jq -r ".sources.\"$source_name\".url" "$app_settings_file")
  local source_root_dir=$(jq -r ".sources.\"$source_name\".root_dir" "$app_settings_file")
  local source_unzip=$(jq -r ".sources.\"$source_name\".unzip" "$app_settings_file")

  # Source Filter
  local source_filter="$system_tmp_dir/files.filter"
  local roms_all_dir
  if [ "$(jq -r ".roms.sources.\"$source_name\" | has(\"files\")" "$system_settings_file")" = "true" ]; then
    jq -r "if .roms.sources.\"$source_name\" | has(\"files\") then .roms.sources.\"$source_name\".files[] else [] end" "$system_settings_file" > "$source_filter"
    roms_all_dir="$HOME/RetroPie/roms/$system/-ALL-"
  else
    roms_all_dir="$HOME/RetroPie/roms/$system"
  fi

  # Target
  mkdir -p "$roms_all_dir"

  if [ "$source_type" = "torrent" ]; then
    # Torrent Info
    local torrent_file="$tmp_dir/$source_name.torrent"

    # Download target
    local rom_source_dir="/var/lib/transmission-daemon/downloads/$source_root_dir"

    # Download torrent
    download_file "$source_url" "$torrent_file"
    "$app_dir/bin/tools/torrent.sh" "$torrent_file" "$source_filter"
  elif [ "$source_type" = "http" ]; then
    local rom_source_dir="$system_tmp_dir/downloads"
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
  local system="$1"

  # Configuration
  local system_config_dir="$app_dir/config/systems/$system"
  local system_settings_file="$system_config_dir/settings.json"

  jq -r '.roms.sources | keys[]' "$system_settings_file" | while read source_name; do
    download_source "$system" "$source_name"
  done
}

organize_system() {
  # Arguments
  local system="$1"

  # Configuration
  local system_config_dir="$app_dir/config/systems/$system"
  local system_settings_file="$system_config_dir/settings.json"

  # Target
  local roms_dir="$HOME/RetroPie/roms/$system"
  local roms_all_dir="$roms_dir/-ALL-"
  local roms_blocked_dir="$roms_dir/.blocked"
  local roms_duplicates_dir="$roms_dir/.duplicates"
  mkdir -p "$roms_all_dir" "$roms_blocked_dir" "$roms_duplicates_dir"

  # Move everything back into ALL so we can start from scratch
  find "$roms_duplicates_dir" "$roms_blocked_dir" -mindepth 1 -maxdepth 1 -exec mv "{}" "$roms_all_dir" \;

  # Allowlist
  # - Keywords
  if [ $(jq -r '.roms.allowlists | has("keywords")' "$system_settings_file") = "true" ]; then
    local keywords=$(jq -r '.roms.allowlists.keywords[]' "$system_settings_file" | sed 's/[][()\.^$?*+]/\\&/g' | paste -sd '|')
    find "$roms_all_dir/" -mindepth 1 -regextype posix-extended ! -regex ".*($keywords).*" -exec mv "{}" "$roms_blocked_dir/" \;
  fi

  # Blocklist
  # - Keywords
  if [ $(jq -r '.roms.blocklists | has("keywords")' "$system_settings_file") = "true" ]; then
    local blocklist=$(jq -r '.roms.blocklists.keywords[]' "$system_settings_file" | sed 's/[][()\.^$?*+]/\\&/g' | paste -sd '|')
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

theme_system() {
  local theme="$1"
  local bezelproject_bin=$HOME/RetroPie/retropiemenu/bezelproject.sh
  
  "$bezelproject_bin" install_bezel_packsa "$theme" "thebezelproject"
  "$bezelproject_bin" install_bezel_pack "$theme" "thebezelproject"
}
