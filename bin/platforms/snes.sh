#!/bin/bash

##############
# Emulator: SNES
##############

set -e

# Input Lag
crudini --set /opt/retropie/configs/snes/retroarch.cfg '' 'run_ahead_enabled' '"true"'
crudini --set /opt/retropie/configs/snes/retroarch.cfg '' 'run_ahead_frames' '"1"'
crudini --set /opt/retropie/configs/snes/retroarch.cfg '' 'run_ahead_secondary_instance' '"true"'
