#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='retropie-scriptmodules'
setup_module_desc='Custom RetroPie scriptmodules'

build() {
  local target_path="$retropie_setup_dir/ext/retrokit/scriptmodules"
  mkdir -pv "$target_path"

  # Merge script modules from retrokit and profiles into a single directory
  local scriptmodules_path=$(mktemp -d -p "$tmp_ephemeral_dir")
  each_path '{ext_dir}/scriptmodules' rsync -a '{}/' "$scriptmodules_path/"

  # Take the merged directory and rsync that as the source of truth
  rsync -av "$scriptmodules_path/" "$target_path/" --delete
}

remove() {
  rm -rfv "$retropie_setup_dir/ext/retrokit/"
}

setup "${@}"
