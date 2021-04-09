#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

install() {
  sudo apt install -y mame-tools
}

uninstall() {
  sudo apt remove -y mame-tools
}

"${@}"
