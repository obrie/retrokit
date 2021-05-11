#!/bin/bash

set -ex

system='dreamcast'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

install() {
  ini_merge "$system_config_dir/redream.cfg" '/opt/retropie/emulators/redream/redream.cfg'
}

uninstall() {
  restore '/opt/retropie/emulators/redream/redream.cfg'
}

"${@}"
