#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

install() {
  # Run the uninstall command so that any old scriptmodules are gone
  uninstall

  echo "Copying RetroPie scriptmodules to $HOME/RetroPie-Setup/ext/retrokit"
  mkdir "$HOME/RetroPie-Setup/ext/retrokit"
  cp -a "$bin_dir/scriptmodules" "$HOME/RetroPie-Setup/ext/retrokit"
}

uninstall() {
  rm -rf "$HOME/RetroPie-Setup/ext/retrokit/"
}

"${@}"
