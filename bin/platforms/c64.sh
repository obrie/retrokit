#!/bin/bash

##############
# Platform: Commodore 64
##############

set -ex

DIR=$( dirname "$0" )
. $DIR/common.sh

PLATFORM="c64"
CONFIG_DIR="$APP_DIR/config/platforms/$PLATFORM"
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

  # Enable fast startup
  crudini --set /opt/retropie/configs/all/retroarch-core-options.cfg '' 'vice_autoloadwarp' '"enabled"'

  # Default Start command
  crudini --set /opt/retropie/configs/all/retroarch-core-options.cfg '' 'vice_mapper_start' '"RETROK_F1"'

  setup_platform "$PLATFORM"
}

download() {
  # Target
  roms_dir="/home/pi/RetroPie/roms/$PLATFORM"
  roms_all_dir="$roms_dir/-ALL-"
  roms_duplicates_dir="$roms_dir/.duplicates"
  mkdir -p "$roms_duplicates_dir"

  if [ ! "$(ls -A $roms_all_dir)" ]; then
    # Download according to settings file
    download_platform "$PLATFORM"
  fi

  organize_platform "$PLATFORM"

  # Clean up duplicates
  ls $roms_all_dir | grep -oE "^[^(]+" | uniq | while read -r game; do
    find "$roms_all_dir" -type f -name "$game \(*" | sort -r | tail -n +2 | xargs -d'\n' -I{} mv "{}" "$roms_duplicates_dir/"
  done
}

if [[ $# -lt 1 ]]; then
  usage
fi

command="$1"
popd
"$command" "$@"
