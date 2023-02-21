#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='emulationstation-configscripts'
setup_module_desc='EmulationStation scripts for automatic input configuration'

configscripts_dir="$retropie_dir/supplementary/emulationstation/scripts/configscripts"

build() {
  while read -r autoconfig_name; do
    file_cp "{ext_dir}/es-configscripts/$autoconfig_name.sh" "$configscripts_dir/$autoconfig_name.sh" as_sudo=true backup=false envsubst=false
  done < <(setting '.hardware.controllers.autoconfig[]')
}

remove() {
  # Remove autoconfig scripts
  while read -r autoconfig_name; do
    sudo rm -fv "$configscripts_dir/$autoconfig_name.sh"
  done < <(setting '.hardware.controllers.autoconfig[]')
}

setup "${@}"
