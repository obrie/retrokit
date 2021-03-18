#!/bin/bash

##############
# Common functions used across platform installs
##############

export DIR=$(dirname "$0")
export APP_DIR=$(cd "$DIR/../.." && pwd)
export APP_SETTINGS_FILE="$APP_DIR/config/settings.json"
export TMP_DIR="$APP_DIR/tmp"

scrape_platform() {
  # Arguments
  platform="$1"

  # Kill emulation station
  killall emulationstation

  # Scrape
  /opt/retropie/supplementary/skyscraper/Skyscraper -p "$platform" -g "/home/pi/.emulationstation/gamelists/$system" -o "/home/pi/.emulationstation/downloaded_media/$platform" -s screenscraper --flags "unattend,skipped,videos"

  # Generate game list
  /opt/retropie/supplementary/skyscraper/Skyscraper -p "$platform" -g "/home/pi/.emulationstation/gamelists/$system" -o "/home/pi/.emulationstation/downloaded_media/$platform" --flags "unattend,skipped,videos"
}

setup_platform() {
  # Arguments
  platform="$1"

  # Configuration
  platform_config_dir="$APP_DIR/config/platforms/$platform"
  platform_settings_file="$platform_config_dir/settings.json"

  if [ $(jq -r 'has("emulators")') = "true" ]; then
    jq -r '.emulators[]' "$platform_settings_file" | while read emulator; do
      # Retroarch
      mkdir -p "/opt/retropie/configs/all/retroarch/config/$emulator/"

      # Core Options overides (https://retropie.org.uk/docs/RetroArch-Core-Options/)
      retropie_configs_dir="/opt/retropie/configs/all"
      find "$platform_config_dir/retroarch_opts" -iname "*.opt" | while read override_file; do
        opt_name=$(basename "$override_file")
        opt_file="$retropie_configs_dir/retroarch/config/$emulator/$opt_name"
        touch "$opt_file"
        crudini --merge --output="$opt_file" "$retropie_configs_dir/retroarch-core-options.cfg" < "$override_file"
      done
    done
  fi
}

download_platform() {
  # Arguments
  platform="$1"

  # Configuration
  platform_config_dir="$APP_DIR/config/platforms/$platform"
  platform_settings_file="$platform_config_dir/settings.json"

  # Source
  source_name=$(jq -r '.source.name' "$platform_settings_file")
  source_unzip=$(jq -r '.source.unzip' "$platform_settings_file")
  source_type=$(jq -r ".sources.$source_name.type" "$APP_SETTINGS_FILE")
  source_root_dir=$(jq -r ".sources.$source_name.root_dir" "$APP_SETTINGS_FILE")

  # Source Filter
  source_filter="$TMP_DIR/$platform.filter"
  jq -r 'if .roms.source | has("files") then .roms.source.files[] else .roms.default[] end' "$platform_settings_file" > "$source_filter"

  # Target
  roms_all_dir="/home/pi/RetroPie/roms/$platform/-ALL-"
  mkdir -p "$roms_all_dir"

  if [ "$source_type" = "torrent" ]; then
    # Torrent Info
    torrent_url=$(jq -r ".sources.$source_name.url" "$APP_SETTINGS_FILE")
    torrent_file="$TMP_DIR/$platform.torrent"

    # Download info
    rom_source_dir="/var/lib/transmission-daemon/downloads/$source_root_dir"

    # Download torrent
    wget -nc "$torrent_url" -O "$torrent_file" || true
    "$APP_DIR/bin/tools/torrent.sh" "$torrent_file" "$source_filter"
  elif [ "$source_type" = "http" ]; then
    # HTTP Info
    base_url=$(jq -r ".sources.$source_name.url" "$APP_SETTINGS_FILE")

    # Download info
    rom_source_dir="$TMP_DIR"

    # Download URLs
    cat "$source_filter" | xargs -t -d'\n' -I{} wget -nc "$base_url/{}"
  else
    echo "Invalid source type: $source_type"
    exit 1
  fi

  if [ "$source_unzip" = "true" ]; then
    # Extract files
    unzip -o "$rom_source_dir/*.zip" -d "$roms_all_dir/"
    sudo rm "$rom_source_dir/*.zip"
  else
    sudo mv "$rom_source_dir/*" "$roms_all_dir/"
  fi
}

organize_platform() {
  # Arguments
  platform="$1"

  # Configuration
  platform_config_dir="$APP_DIR/config/platforms/$platform"
  platform_settings_file="$platform_config_dir/settings.json"

  # Target
  roms_dir="/home/pi/RetroPie/roms/$platform"
  roms_all_dir="$roms_dir/-ALL-"
  roms_blocked_dir="$roms_dir/.blocked"
  mkdir -p "$roms_all_dir" "$roms_blocked_dir"

  # Block games
  if [ $(jq -r '.roms | has("blocklist")' "$platform_settings_file") = "true" ]; then
    blocklist=$(jq -r '.roms.blocklist[]' "$platform_settings_file" | sed 's/[][()\.^$?*+]/\\&/g' | tr '\n' '|' | sed 's/|$//')
    find "$roms_all_dir/" -regextype posix-extended -regex ".*($blocklist).*" -exec mv "{}" "$roms_blocked_dir/" \;
  fi

  # Add defaults
  jq -r ".roms.default[]" "$platform_settings_file" | xargs -t -d'\n' -I{} ln -fs "$roms_all_dir/{}" "$roms_dir/{}"
}
