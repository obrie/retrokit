#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='retropie-scriptmodules'
setup_module_desc='Custom RetroPie scriptmodules'

build() {
  local target_path="$HOME/RetroPie-Setup/ext/retrokit/scriptmodules"
  mkdir -pv "$target_path"

  # Merge script modules from retrokit and profiles into a single directory
  mkdir -p "$tmp_ephemeral_dir/scriptmodules"
  each_path '{ext_dir}/scriptmodules' rsync -a '{}/' "$tmp_ephemeral_dir/scriptmodules/"

  # Take the merged directory and rsync that as the source of truth
  rsync -av "$tmp_ephemeral_dir/scriptmodules/" "$target_path/" --delete
}

remove() {
  rm -rfv "$HOME/RetroPie-Setup/ext/retrokit/"
}

setup "${@}"
