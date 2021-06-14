#!/bin/bash

system='psp'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

install() {
  mkdir -pv /opt/retropie/configs/psp/PSP/Cheats
  download 'https://github.com/Saramagrean/CWCheat-Database-Plus-/raw/master/cheat.db' '/opt/retropie/configs/psp/PSP/Cheats/cheat.db'
}

uninstall() {
  rm /opt/retropie/configs/psp/PSP/Cheats/cheat.db
}

"${@}"
