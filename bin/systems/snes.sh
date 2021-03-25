#!/bin/bash

##############
# System: SNES
##############

set -ex

dir=$( dirname "$0" )
. $dir/common.sh

# System settings
system="snes"
init "$system"

# Configurations
retroarch_config="/opt/retropie/configs/$system/emulators.cfg"

usage() {
  echo "usage: $0 <setup|download>"
  exit 1
}

setup() {
  # Emulators
  crudini --set "/opt/retropie/configs/$system/emulators.cfg" '' 'default' '"lr-snes9x"'

  # Input Lag
  crudini --set "$retroarch_config" '' 'run_ahead_enabled' '"true"'
  crudini --set "$retroarch_config" '' 'run_ahead_frames' '"1"'
  crudini --set "$retroarch_config" '' 'run_ahead_secondary_instance' '"true"'
}

download() {
  download_system "$system"
  organize_system "$system"
  scrape_system "$system" "screenscraper"
  theme_system "SNES"
}

if [[ $# -lt 1 ]]; then
  usage
fi

command="$1"
shift
"$command" "$@"
