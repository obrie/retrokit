#!/bin/bash

##############
# System: Playstation
##############

set -ex

dir=$( dirname "$0" )
. $dir/common.sh

# System settings
system="psx"

# Configurations
retroarch_config="/opt/retropie/configs/$system/emulators.cfg"

usage() {
  echo "usage: $0 <setup|download>"
  exit 1
}

setup() {
  # Emulators
  crudini --set "$retroarch_config" '' 'default' '"lr-pcsx-rearmed"'
}

download() {
  download_system "$system"
  organize_system "$system"
  scrape_system "$system" "screenscraper"
  scrape_system "$system" "thegamesdb"
  theme_system "PSX"
}

if [[ $# -lt 1 ]]; then
  usage
fi

command="$1"
shift
"$command" "$@"
