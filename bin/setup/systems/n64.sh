#!/bin/bash

set -ex

system='n64'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../system-common.sh"

install() {
  ini_merge "$system_config_dir/mupen64plus.cfg" '/opt/retropie/configs/n64/mupen64plus.cfg'
  ini_merge "$system_config_dir/InputAutoCfg.ini" '/opt/retropie/configs/n64/InputAutoCfg.ini'
}

uninstall() {
  restore '/opt/retropie/configs/n64/mupen64plus.cfg'
  restore '/opt/retropie/configs/n64/InputAutoCfg.ini'
}

"${@}"
