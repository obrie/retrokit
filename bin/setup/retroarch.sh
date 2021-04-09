#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

install() {
  ini_merge "$config_dir/retroarch/retroarch.cfg" '/opt/retropie/configs/all/retroarch.cfg'
}

uninstall() {
  restore '/opt/retropie/configs/all/retroarch.cfg'
}

"${@}"
