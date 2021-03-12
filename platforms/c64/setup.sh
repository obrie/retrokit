#!/bin/bash

##############
# Emulator: Commodore 64
##############

set -e

sudo ~/RetroPie-Setup/retropie_packages.sh lr-vice _binary_

# Enable fast startup
crudini --set /opt/retropie/configs/all/retroarch-core-options.cfg '' 'vice_autoloadwarp' '"enabled"'

# Default Start command
crudini --set /opt/retropie/configs/all/retroarch-core-options.cfg '' 'vice_mapper_start' '"RETROK_F1"'

# Set up configurations
mkdir -p /opt/retropie/configs/all/retroarch/config/VICE\ x64/
