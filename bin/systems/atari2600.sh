#!/bin/bash

##############
# System: Atari 2600
##############

set -ex

DIR=$( dirname "$0" )
. $DIR/common.sh

SYSTEM="atari2600"
CONFIG_DIR="$APP_DIR/config/systems/$SYSTEM"
SETTINGS_FILE="$CONFIG_DIR/settings.json"

usage() {
  echo "usage: $0 <setup|download>"
  exit 1
}

setup() {
  # Emulators
  crudini --set "/opt/retropie/configs/$SYSTEM/emulators.cfg" '' 'default' '"lr-stella"'

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
  theme_system "Atari2600"
}

if [[ $# -lt 1 ]]; then
  usage
fi

command="$1"
shift
"$command" "$@"
