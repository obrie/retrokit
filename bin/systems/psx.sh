#!/bin/bash

##############
# System: Playstation
##############

set -ex

DIR=$( dirname "$0" )
. $DIR/common.sh

SYSTEM="psx"
CONFIG_DIR="$APP_DIR/config/systems/$SYSTEM"
SETTINGS_FILE="$CONFIG_DIR/settings.json"

usage() {
  echo "usage: $0 <setup|download>"
  exit 1
}

setup() {
  # Emulators
  crudini --set /opt/retropie/configs/psx/emulators.cfg '' 'default' '"lr-pcsx-rearmed"'
}


download() {
  # Target
  roms_dir="/home/pi/RetroPie/roms/$SYSTEM"
  roms_all_dir="$roms_dir/-ALL-"

  if [ ! "$(ls -A $roms_all_dir)" ]; then
    # Download according to settings file
    download_system "$SYSTEM"
  fi

  organize_system "$SYSTEM"
  scrape_system "$SYSTEM" "screenscraper"
  scrape_system "$SYSTEM" "thegamesdb"
}

if [[ $# -lt 1 ]]; then
  usage
fi

command="$1"
shift
"$command" "$@"
