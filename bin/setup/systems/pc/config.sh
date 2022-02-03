#!/bin/bash

system='pc'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

install() {
  # Sound driver
  sudo apt install -y fluid-soundfont-gm

  configure
}

configure() {
  ini_merge "$system_config_dir/dosbox-staging.conf" '/opt/retropie/configs/pc/dosbox-staging.conf'
  ini_merge "$system_config_dir/dosbox-SVN.conf" '/opt/retropie/configs/pc/dosbox-SVN.conf'
}

restore() {
  restore_file '/opt/retropie/configs/pc/dosbox-staging.conf' delete_src=true
  restore_file '/opt/retropie/configs/pc/dosbox-SVN.conf' delete_src=true
}

uninstall() {
  sudo apt remove -y fluid-soundfont-gm
  restore
}

"${@}"
