#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

install() {
  file_cp "$app_dir/bin/runcommand/onstart.sh" '/opt/retropie/configs/all/runcommand-onstart.sh' envsubst=false
  file_cp "$app_dir/bin/runcommand/onend.sh" '/opt/retropie/configs/all/runcommand-onend.sh' envsubst=false
  cp "$app_dir/bin/runcommand/tty.py" '/opt/retropie/configs/all/runcommand-tty.py'

  ini_merge "$config_dir/runcommand/runcommand.cfg" '/opt/retropie/configs/all/runcommand.cfg'
}

uninstall() {
  restore '/opt/retropie/configs/all/runcommand.cfg' delete_src=true
  restore '/opt/retropie/configs/all/runcommand-onstart.sh' delete_src=true
  restore '/opt/retropie/configs/all/runcommand-onend.sh' delete_src=true
  rm -f '/opt/retropie/configs/all/runcommand-tty.py'
}

"${@}"
