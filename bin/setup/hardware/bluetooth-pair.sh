#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../common.sh"

install() {
  sudo $HOME/RetroPie-Setup/retropie_packages.sh bluetooth gui
}

uninstall() {
  return
}

"${@}"
