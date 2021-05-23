#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

install() {
  backup_and_restore "$HOME/scriptmodules/emulators/advmame.sh"
  patch -p1 --forward "$HOME/RetroPie-Setup" "$config_dir/retropie/patches.diff"
}

uninstall() {
  restore "$HOME/scriptmodules/emulators/advmame.sh"
}

"${@}"
