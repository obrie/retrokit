#!/bin/bash

##############
# Platform: NES
##############

set -e

# Input Lag
crudini --set /opt/retropie/configs/nes/retroarch.cfg '' 'run_ahead_enabled' '"true"'
crudini --set /opt/retropie/configs/nes/retroarch.cfg '' 'run_ahead_frames' '"1"'
crudini --set /opt/retropie/configs/nes/retroarch.cfg '' 'run_ahead_secondary_instance' '"true"'
