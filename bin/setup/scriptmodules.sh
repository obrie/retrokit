#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

install() {
  while read -r filepath; do
    local source_path="$config_dir/scriptmodules/$filepath"
    local target_path="$HOME/RetroPie-Setup/scriptmodules/$filepath"

    # Remove any backup files for the scriptmodule
    rm -f "$target_path.rk-src"

    # Copy over the scriptmodule
    file_cp "$source_path" "$target_path"
  done < <(find "$config_dir/scriptmodules" -type f -printf '%P\n')
}

uninstall() {
  while read -r filepath; do
    restore "$HOME/RetroPie-Setup/scriptmodules/$filepath" delete_src=true
  done < <(find "$config_dir/scriptmodules" -type f -printf '%P\n')
}

"${@}"
