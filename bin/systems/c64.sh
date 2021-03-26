#!/bin/bash

##############
# System: Commodore 64
##############

set -ex

dir=$( dirname "$0" )
. $dir/common.sh

# System settings
system="c64"
init "$system"

# Configurations
retroarch_config="/opt/retropie/configs/$system/emulators.cfg"

usage() {
  echo "usage: $0 <setup|download>"
  exit 1
}

setup() {
  # Install packages
  if [ ! -d "/opt/retropie/libretrocores/lr-vice/" ]; then
    sudo $HOME/RetroPie-Setup/retropie_packages.sh lr-vice _binary_
  fi

  # Emulators
  crudini --set "$retroarch_config" '' 'default' '"lr-vice"'

  # Enable fast startup
  crudini --set "$retroarch_cores_config" '' 'vice_autoloadwarp' '"enabled"'

  # Default start command
  crudini --set "$retroarch_cores_config" '' 'vice_mapper_start' '"RETROK_F1"'

  setup_system "$system"
}

download() {
  download_system "$system"
  organize_system "$system"
  scrape_system "$system" "screenscraper"
  build_gamelist "$system"
  theme_system "C64"
}

if [[ $# -lt 1 ]]; then
  usage
fi

command="$1"
shift
"$command" "$@"
