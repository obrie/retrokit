#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../../common.sh"

argon_bin="$tmp_dir/argon1.sh"

download_argon() {
  download 'https://download.argon40.com/argon1.sh' "$argon_bin"
}

install() {
  if [ ! `command -v argonone-config` ]; then
    download_argon
    bash "$argon_bin"
    rm "$argon_bin"
  else
    echo 'argoneone scripts are already installed'
  fi
}

uninstall() {
  if [ ! `command -v argonone-uninstall` ]; then
    echo 'Y' | argonone-uninstall
  fi
}

"${@}"
