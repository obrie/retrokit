#!/bin/bash

##############
# Platform: Arcade
##############

set -ex

APP_DIR=$(cd "$( dirname "$0" )/../.." && pwd)
CONFIG_DIR="$APP_DIR/platforms/config/arcade"

usage() {
  echo "usage: $0"
  exit 1
}

setup() {
  # Input Lag
  crudini --set /opt/retropie/configs/snes/retroarch.cfg '' 'run_ahead_enabled' '"true"'
  crudini --set /opt/retropie/configs/snes/retroarch.cfg '' 'run_ahead_frames' '"1"'
  crudini --set /opt/retropie/configs/snes/retroarch.cfg '' 'run_ahead_secondary_instance' '"true"'
}

if [[ $# -lt 1 ]]; then
  usage
fi

command="$1"
popd
"$command" "$@"
