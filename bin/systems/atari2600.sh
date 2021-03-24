#!/bin/bash

##############
# System: Atari 2600
##############

set -ex

dir=$( dirname "$0" )
. $dir/common.sh

# System settings
system="atari2600"

# Configurations
retroarch_config="/opt/retropie/configs/$system/emulators.cfg"

usage() {
  echo "usage: $0 <setup|download>"
  exit 1
}

setup() {
  # Emulators
  crudini --set "$retroarch_config" '' 'default' '"lr-stella"'

  setup_system "$system"
}

download() {
  download_system "$system"
  organize_system "$system"
  scrape_system "$system" "screenscraper"
  theme_system "Atari2600"
}

if [[ $# -lt 1 ]]; then
  usage
fi

command="$1"
shift
"$command" "$@"
