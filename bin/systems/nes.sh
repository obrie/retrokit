#!/bin/bash

##############
# System: NES
##############

set -ex

DIR=$( dirname "$0" )
. $DIR/common.sh

SYSTEM="nes"
CONFIG_DIR="$APP_DIR/config/systems/$SYSTEM"
SETTINGS_FILE="$CONFIG_DIR/settings.json"

usage() {
  echo "usage: $0 <setup|download>"
  exit 1
}

setup() {
  # Emulators
  crudini --set /opt/retropie/configs/nes/emulators.cfg '' 'default' '"lr-fceumm"'

  # Input Lag
  crudini --set /opt/retropie/configs/nes/retroarch.cfg '' 'run_ahead_enabled' '"true"'
  crudini --set /opt/retropie/configs/nes/retroarch.cfg '' 'run_ahead_frames' '"1"'
  crudini --set /opt/retropie/configs/nes/retroarch.cfg '' 'run_ahead_secondary_instance' '"true"'

  # Sprite performance
  crudini --set /opt/retropie/configs/all/retroarch-core-options.cfg '' 'fceumm_show_adv_system_options' '"enabled"'
  crudini --set /opt/retropie/configs/all/retroarch-core-options.cfg '' 'fceumm_nospritelimit' '"enabled"'

  # Audio quality
  crudini --set /opt/retropie/configs/all/retroarch-core-options.cfg '' 'fceumm_sndquality' '"High"'
}

download() {
  # Target
  roms_dir="/home/pi/RetroPie/roms/$SYSTEM"
  roms_all_dir="$roms_dir/-ALL-"
  mkdir -p "$roms_all_dir"

  if [ "$(ls -A $roms_all_dir | wc -l)" -eq 0 ]; then
    # Download according to settings file
    download_system "$SYSTEM"
  else
    echo "$roms_all_dir is not empty: skipping download"
  fi

  organize_system "$SYSTEM"
}

scrape() {
  scrape_system "$SYSTEM"
}

if [[ $# -lt 1 ]]; then
  usage
fi

command="$1"
shift
"$command" "$@"
