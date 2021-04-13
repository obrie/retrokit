#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

install() {
  find "$config_dir/scriptmodules" -iname "*.sh" | while read scriptmodule; do
    local script_name=$(basename "$scriptmodule")
    conf_copy "$scriptmodule" "$HOME/RetroPie-Setup/scriptmodules/$script_name"
  done
}

uninstall() {
  echo 'No uninstall for script modules'
}

"${@}"
