#!/bin/bash

system='pc'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

install() {
  # Sound driver
  sudo apt install -y fluid-soundfont-gm
}

uninstall() {
  sudo apt remove -y fluid-soundfont-gm
}

"${@}"
