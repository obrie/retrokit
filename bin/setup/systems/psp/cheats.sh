#!/bin/bash

system='psp'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

setup_module_id='system/psp/cheats'
setup_module_desc='Cheats database for PSP'

build() {
  mkdir -pv "$retropie_system_config_dir/PSP/Cheats"
  download 'https://github.com/Saramagrean/CWCheat-Database-Plus-/raw/master/cheat.db' "$retropie_system_config_dir/PSP/Cheats/cheat.db"
}

remove() {
  rm -fv "$retropie_system_config_dir/PSP/Cheats/cheat.db"
}

setup "${@}"
