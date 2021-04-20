#!/bin/bash

set -ex

system='n64'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../system-common.sh"

install() {
  ini_merge "$system_config_dir/mupen64plus.cfg" '/opt/retropie/configs/n64/mupen64plus.cfg'
}

uninstall() {
  restore '/opt/retropie/configs/n64/mupen64plus.cfg'
}

"${@}"
