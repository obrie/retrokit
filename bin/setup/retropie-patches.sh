#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

install() {
  if patch -p1 -N --dry-run --silent -d "$HOME/RetroPie-Setup" < "$config_dir/retropie/patches.diff"; then
    backup_and_restore "$HOME/RetroPie-Setup/scriptmodules/emulators/advmame.sh"
    patch -p1 -N -d "$HOME/RetroPie-Setup" < "$config_dir/retropie/patches.diff"
  fi
}

uninstall() {
  restore "$HOME/RetroPie-Setup/scriptmodules/emulators/advmame.sh" delete_src=true
}

"${@}"
