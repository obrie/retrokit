#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

install() {
  local target_path="$HOME/RetroPie-Setup/ext/retrokit/scriptmodules"
  mkdir -pv "$target_path"
  rsync -av "$bin_dir/scriptmodules/" "$target_path/" --delete
}

uninstall() {
  rm -rfv "$HOME/RetroPie-Setup/ext/retrokit/"
}

"${@}"
