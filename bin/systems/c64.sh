#!/bin/bash

##############
# System: Commodore 64
##############

set -ex

DIR=$( dirname "$0" )
. $DIR/common.sh

SYSTEM="c64"
CONFIG_DIR="$APP_DIR/config/systems/$SYSTEM"
SETTINGS_FILE="$CONFIG_DIR/settings.json"

usage() {
  echo "usage: $0 <setup|download>"
  exit 1
}

setup() {
  # Install packages
  if [ ! -d "/opt/retropie/libretrocores/lr-vice/" ]; then
    sudo ~/RetroPie-Setup/retropie_packages.sh lr-vice _binary_
  fi

  # Emulators
  crudini --set "/opt/retropie/configs/$SYSTEM/emulators.cfg" '' 'default' '"lr-vice"'

  # Enable fast startup
  crudini --set /opt/retropie/configs/all/retroarch-core-options.cfg '' 'vice_autoloadwarp' '"enabled"'

  # Default Start command
  crudini --set /opt/retropie/configs/all/retroarch-core-options.cfg '' 'vice_mapper_start' '"RETROK_F1"'

  setup_system "$SYSTEM"
}

download() {
  # Target
  roms_dir="/home/pi/RetroPie/roms/$SYSTEM"
  roms_all_dir="$roms_dir/-ALL-"

  if [ "$(ls -A $roms_all_dir | wc -l)" -eq 0 ]; then
    # Download according to settings file
    download_system "$SYSTEM"
  else
    echo "$roms_all_dir is not empty: skipping download"
  fi

  organize_system "$SYSTEM"
  scrape_system "$SYSTEM" "screenscraper"
  theme_system "C64"
}

if [[ $# -lt 1 ]]; then
  usage
fi

command="$1"
shift
"$command" "$@"
