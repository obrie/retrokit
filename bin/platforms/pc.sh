#!/bin/bash

##############
# Platform: PC
# 
# Configs:
# * ~/.dosbox/dosbox-SVN.conf
##############

set -ex

APP_DIR=$(cd "$( dirname "$0" )/../.." && pwd)
APP_SETTINGS_FILE="$APP_DIR/config/settings.json"
TMP_DIR="$APP_DIR/tmp"
PLATFORM_CONFIG_DIR="$APP_DIR/config/platforms/pc"
PLATFORM_SETTINGS_FILE="$PLATFORM_CONFIG_DIR/settings.json"

setup() {
  # Install emulators
  sudo ~/RetroPie-Setup/retropie_packages.sh dosbox _binary_
  sudo ~/RetroPie-Setup/retropie_packages.sh lr-dosbox-pure _binary_

  # Sound driver
  sudo apt install fluid-soundfont-gm

  # Set up [Gravis Ultrasound](https://retropie.org.uk/docs/PC/#install-gravis-ultrasound-gus):

  https://github.com/Voljega/ExoDOSConverter
}

download() {
  roms_dir="/home/pi/RetroPie/roms/pc"
  roms_files_dir="$roms_dir/.files"
  torrent_url=$(jq -r '.sources.exodos.url' "$APP_SETTINGS_FILE")
  torrent_file="$TMP_DIR/pc.torrent"
  torrent_filter="$TMP_DIR/pc.filter"
  rom_source_dir="/var/lib/transmission-daemon/downloads/$(jq -r '.sources.exodos.root_dir' "$APP_SETTINGS_FILE")"

  # Download torrent
  wget -nc "$torrent_url" -O "$torrent_file" || true
  jq -r '.roms.default[]' "$PLATFORM_SETTINGS_FILE" > "$torrent_filter"
  "$APP_DIR/bin/torrent.sh" "$torrent_file" "$torrent_filter"

  # Extract files
  unzip -o "$rom_source_dir/*.zip" -d "$roms_files_dir/"
  sudo rm "$rom_source_dir/*.zip"

  # Add defaults
  # jq -r ".roms.default[]" "$SETTINGS_FILE" | xargs -d'\n' -I{} ln -fs "$roms_all_dir/{}" "$roms_dir/{}"
}

if [[ $# -lt 1 ]]; then
  usage
fi

command="$1"
popd
"$command" "$@"
