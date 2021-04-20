#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

install() {
  while read -r filepath; do
    local source_path="$config_dir/scriptmodules/$filepath"
    local target_path="$HOME/RetroPie-Setup/scriptmodules/$filepath"

    # Remove any backup files for the scriptmodule
    rm -f "$target_path.orig"

    # Copy over the scriptmodule
    cp "$source_path" "$target_path"
  done < <(find "$config_dir/scriptmodules" -type f -printf '%P\n')
}

uninstall() {
  echo 'No uninstall for script modules'
}

"${@}"
