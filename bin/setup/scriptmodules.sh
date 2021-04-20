#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

install() {
  cp -R "$config_dir/scriptmodules/*" "$HOME/RetroPie-Setup/scriptmodules/"
}

uninstall() {
  echo 'No uninstall for script modules'
}

"${@}"
