#!/bin/bash

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

# retropie_configs_dir="/opt/retropie/configs/all"
# retroarch_config_dir="$retropie_configs_dir/retroarch/config"

# c64_system="VICE x64"
# c64_retroarch_dir="$retroarch_config_dir/$c64_system"

# # Core Options (https://retropie.org.uk/docs/RetroArch-Core-Options/)
# find "$c64_retroarch_dir" -iname "*overrides" | while read override_file; do
#   opt_name=$(basename -s .overrides "$override_file")
#   opt_file="$c64_retroarch_dir/$opt_name"
#   cp $retropie_configs_dir/retroarch-core-options.cfg "$opt_file"
#   crudini --merge "$opt_file" < "$override_file"
# done