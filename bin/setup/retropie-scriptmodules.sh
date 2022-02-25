#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='retropie-scriptmodules'
setup_module_desc='Custom RetroPie scriptmodules'

build() {
  local target_path="$HOME/RetroPie-Setup/ext/retrokit/scriptmodules"
  mkdir -pv "$target_path"
  rsync -av "$bin_dir/scriptmodules/" "$target_path/" --delete
}

remove() {
  rm -rfv "$HOME/RetroPie-Setup/ext/retrokit/"
}

setup "${@}"
