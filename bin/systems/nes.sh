#!/bin/bash

##############
# System: NES
##############

set -ex

dir=$( dirname "$0" )
. $dir/common.sh

# System settings
system="nes"
init "$system"

# Configurations
retroarch_config="/opt/retropie/configs/$system/emulators.cfg"

usage() {
  echo "usage: $0 <setup|download>"
  exit 1
}

setup() {
  # Emulators
  crudini --set "$retroarch_config" '' 'default' '"lr-fceumm"'

  # Input Lag
  crudini --set "$retroarch_config" '' 'run_ahead_enabled' '"true"'
  crudini --set "$retroarch_config" '' 'run_ahead_frames' '"1"'
  crudini --set "$retroarch_config" '' 'run_ahead_secondary_instance' '"true"'

  # Sprite performance
  crudini --set "$retroarch_cores_config" '' 'fceumm_show_adv_system_options' '"enabled"'
  crudini --set "$retroarch_cores_config" '' 'fceumm_nospritelimit' '"enabled"'

  # Audio quality
  crudini --set "$retroarch_cores_config" '' 'fceumm_sndquality' '"High"'

  # Cheats
  local cheats_dir="/opt/retropie/configs/all/retroarch/cheats/$system"
  mkdir -p "$cheats_dir"
  rm -f "$cheats_dir/FCEUmm"
  ln -fs "/opt/retropie/configs/all/retroarch/cheats/Nintendo - Nintendo Entertainment System" "$cheats_dir/FCEUmm"
  crudini --set "/opt/retropie/configs/$system/retroarch.cfg" '' 'cheat_database_path' "$cheats_dir"
}

download() {
  download_system "$system"
  organize_system "$system"
  scrape_system "$system" "screenscraper"
  build_gamelist "$system"
  theme_system "NES"
}

if [[ $# -lt 1 ]]; then
  usage
fi

command="$1"
shift
"$command" "$@"
