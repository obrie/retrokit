#!/bin/bash

##############
# System: Game Gear
##############

set -ex

dir=$( dirname "$0" )
. $dir/common.sh

# System settings
system="megadrive"
init "$system"

# Configurations
retroarch_config="/opt/retropie/configs/$system/emulators.cfg"

usage() {
  echo "usage: $0 <setup|download>"
  exit 1
}

setup() {
  # Emulators
  crudini --set "$retroarch_config" '' 'default' '"lr-genesis-plus-gx"'

  # Naming
  xmlstarlet ed -L -u "systemList/system[name=\"$system\"]/theme" -v "genesis" "$es_systems_config"

  setup_system "$system"
}

download() {
  download_system "$system"
  organize_system "$system"
  scrape_system "$system" "screenscraper"
  theme_system "MegaDrive"
}

if [[ $# -lt 1 ]]; then
  usage
fi

command="$1"
shift
"$command" "$@"
