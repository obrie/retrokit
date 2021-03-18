#!/bin/bash

##############
# Platform: NES
##############

set -ex

DIR=$( dirname "$0" )
. $DIR/common.sh

PLATFORM="nes"
CONFIG_DIR="$APP_DIR/config/platforms/$PLATFORM"
SETTINGS_FILE="$CONFIG_DIR/settings.json"

setup() {
  # Input Lag
  crudini --set /opt/retropie/configs/nes/retroarch.cfg '' 'run_ahead_enabled' '"true"'
  crudini --set /opt/retropie/configs/nes/retroarch.cfg '' 'run_ahead_frames' '"1"'
  crudini --set /opt/retropie/configs/nes/retroarch.cfg '' 'run_ahead_secondary_instance' '"true"'
}

download() {
  # Target
  roms_all_dir="/home/pi/RetroPie/roms/nes/-ALL-"

  if [ ! "$(ls -A $roms_all_dir)" ]; then
    # Download according to settings file
    download_platform "$PLATFORM"
  fi

  organize_platform "$PLATFORM"
}
