#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

install() {
  backup_and_restore "$HOME/RetroPie-Setup/scriptmodules/emulators/advmame.sh"
  patch -p1 --forward -d "$HOME/RetroPie-Setup" < "$config_dir/retropie/patches.diff"
}

uninstall() {
  restore "$HOME/scriptmodules/emulators/advmame.sh" delete_src=true
}

"${@}"
