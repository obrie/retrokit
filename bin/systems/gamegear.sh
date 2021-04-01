#!/bin/bash

##############
# System: Game Gear
##############

set -ex

dir=$( dirname "$0" )
. $dir/common.sh

# System settings
system="gamegear"
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

  setup_system "$system"

  # Cheats
  local cheats_dir="/opt/retropie/configs/all/retroarch/cheats/$system"
  mkdir -p "$cheats_dir"
  rm -f "$cheats_dir/Genesis Plus GX"
  ln -fs "/opt/retropie/configs/all/retroarch/cheats/Sega - Game Gear" "$cheats_dir/Genesis Plus GX"
  crudini --set "/opt/retropie/configs/$system/retroarch.cfg" '' 'cheat_database_path' "$cheats_dir"
}

download() {
  download_system "$system"
  organize_system "$system"
  scrape_system "$system" "screenscraper"
  build_gamelist "$system"
  theme_system "GameGear"
}

if [[ $# -lt 1 ]]; then
  usage
fi

command="$1"
shift
"$command" "$@"
