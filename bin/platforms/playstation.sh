#!/bin/bash

##############
# Platform: Playstation
##############

set -ex

APP_DIR=$(cd "$( dirname "$0" )/../.." && pwd)
CONFIG_DIR="$APP_DIR/platforms/config/c64"

# Input Lag
crudini --set /opt/retropie/configs/playstation/retroarch.cfg '' 'run_ahead_enabled' '"true"'
crudini --set /opt/retropie/configs/playstation/retroarch.cfg '' 'run_ahead_frames' '"1"'
crudini --set /opt/retropie/configs/playstation/retroarch.cfg '' 'run_ahead_secondary_instance' '"true"'
