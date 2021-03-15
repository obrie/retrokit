#!/bin/bash

APP_DIR=$(cd "$( dirname "$0" )/../.." && pwd)
CONFIG_DIR="$APP_DIR/platforms/config/c64"

##############
# Platform: Commodore 64
##############

set -e

sudo ~/RetroPie-Setup/retropie_packages.sh lr-vice _binary_

# Enable fast startup
crudini --set /opt/retropie/configs/all/retroarch-core-options.cfg '' 'vice_autoloadwarp' '"enabled"'

# Default Start command
crudini --set /opt/retropie/configs/all/retroarch-core-options.cfg '' 'vice_mapper_start' '"RETROK_F1"'

# Set up configurations
mkdir -p /opt/retropie/configs/all/retroarch/config/VICE\ x64/

# Core Options (https://retropie.org.uk/docs/RetroArch-Core-Options/)
retropie_configs_dir="/opt/retropie/configs/all"
find "$CONFIG_DIR/retroarch_opts" -iname "*.opt" | while read override_file; do
  opt_name=$(basename "$override_file")
  opt_file="$retropie_configs_dir/retroarch/config/VICE x64/$opt_name"
  crudini --merge "$retropie_configs_dir/retroarch-core-options.cfg" --output $opt_file < "$override_file"
done
