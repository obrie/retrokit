#!/bin/bash

system='psp'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

setup_module_id='system/psp/cheats'
setup_module_desc='Cheats database for PSP'

build() {
  mkdir -pv /opt/retropie/configs/psp/PSP/Cheats
  download 'https://github.com/Saramagrean/CWCheat-Database-Plus-/raw/master/cheat.db' '/opt/retropie/configs/psp/PSP/Cheats/cheat.db'
}

remove() {
  rm -fv /opt/retropie/configs/psp/PSP/Cheats/cheat.db
}

setup "${@}"
