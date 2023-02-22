#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='retropie-scriptmodules'
setup_module_desc='Custom RetroPie scriptmodules'

build() {
  dir_rsync '{ext_dir}/scriptmodules' "$retropie_setup_dir/ext/retrokit/scriptmodules"
}

remove() {
  rm -rfv "$retropie_setup_dir/ext/retrokit/"
}

setup "${@}"
