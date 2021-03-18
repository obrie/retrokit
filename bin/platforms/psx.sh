#!/bin/bash

##############
# Platform: Playstation
##############

set -ex

DIR=$( dirname "$0" )
. $DIR/common.sh

PLATFORM="psx"
CONFIG_DIR="$APP_DIR/config/platforms/$PLATFORM"
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
  roms_dir="/home/pi/RetroPie/roms/$PLATFORM"
  roms_all_dir="$roms_dir/-ALL-"

  if [ ! "$(ls -A $roms_all_dir)" ]; then
    # Download according to settings file
    download_platform "$PLATFORM"
  fi

  organize_platform "$PLATFORM"
}

if [[ $# -lt 1 ]]; then
  usage
fi

command="$1"
popd
"$command" "$@"
