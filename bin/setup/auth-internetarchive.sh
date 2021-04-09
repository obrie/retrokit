#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

ia_bin="/usr/local/bin/ia"

install() {
  # Install CLI
  if [ ! -s "$ia_bin" ]; then
    download "https://archive.org/download/ia-pex/ia" "$tmp_dir/ia"
    sudo mv "$tmp_dir/ia" "$ia_bin"
  fi
  sudo chmod +x "$ia_bin"

  # Login
  ia configure -u "$IA_USERNAME" -p "$IA_PASSWORD"
}

uninstall() {
  sudo rm -f "$ia_bin" "$HOME/.ia"
}

"${@}"
