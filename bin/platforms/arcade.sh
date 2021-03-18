#!/bin/bash

##############
# Platform: Arcade
##############

set -ex

DIR=$( dirname "$0" )
. $DIR/common.sh

PLATFORM="arcade"
CONFIG_DIR="$APP_DIR/config/platforms/$PLATFORM"
SETTINGS_FILE="$CONFIG_DIR/settings.json"

usage() {
  echo "usage: $0"
  exit 1
}

setup() {
  # Emulators
  crudini --set /opt/retropie/configs/arcade/emulators.cfg '' 'default' '"lr-fbneo"'

  # Input Lag
  crudini --set /opt/retropie/configs/arcade/retroarch.cfg '' 'run_ahead_enabled' '"true"'
  crudini --set /opt/retropie/configs/arcade/retroarch.cfg '' 'run_ahead_frames' '"1"'
  crudini --set /opt/retropie/configs/arcade/retroarch.cfg '' 'run_ahead_secondary_instance' '"true"'
}

download() {
  # Target
  roms_dir="/home/pi/RetroPie/roms/$PLATFORM"
  roms_all_dir="$roms_dir/-ALL-"
  mkdir -p "$roms_all_dir"

  echo "You must install manually."
  # if [ "$(ls -A $roms_all_dir | wc -l)" -eq 0 ]; then
  #   # Download according to settings file
  #   download_platform "$PLATFORM"
  # else
  #   echo "$roms_all_dir is not empty: skipping download"
  # fi

  sed -e "s/<description>\(.*\)<\/description>/<description>\L\1<\/description>/" ./fbneo.dat | xmlstarlet sel -T -t -v '''/datafile/game[
    not(@cloneof) and
    driver/@status = "good" and
    not(contains(description/text(), "japan")) and
    not(contains(description/text(), "bootleg")) and
    not(contains(description/text(), "prototype")) and
    not(contains(description/text(), "korea"))
  ]/description/text()'''

  organize_platform "$PLATFORM"
}

if [[ $# -lt 1 ]]; then
  usage
fi

command="$1"
shift
"$command" "$@"
