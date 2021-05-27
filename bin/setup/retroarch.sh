#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

install() {
  ini_merge "$config_dir/retroarch/retroarch.cfg" '/opt/retropie/configs/all/retroarch.cfg'
  ini_merge "$config_dir/retroarch/retroarch-core-options.cfg" '/opt/retropie/configs/all/retroarch-core-options.cfg' restore=false
}

uninstall() {
  rm -f '/opt/retropie/configs/all/retroarch-core-options.cfg.rk-src'
  restore '/opt/retropie/configs/all/retroarch.cfg' delete_src=true
}

"${@}"
