#!/bin/bash

system='pc'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

setup_module_id='system/pc/config'
setup_module_desc='PC emulator configuration'
setup_module_reconfigure_after_update=true

depends() {
  # Sound driver
  sudo apt-get install -y fluid-soundfont-gm
}

configure() {
  ini_merge '{system_config_dir}/dosbox-staging.conf' '/opt/retropie/configs/pc/dosbox-staging.conf'
  ini_merge '{system_config_dir}/dosbox-SVN.conf' '/opt/retropie/configs/pc/dosbox-SVN.conf'
  file_cp '{system_config_dir}/mapperfiles/default.map' '/opt/retropie/configs/pc/mapperfiles/default.map' backup=false
  sed -i '/^[ \t]*#/d' /opt/retropie/configs/pc/mapperfiles/default.map
}

restore() {
  restore_file '/opt/retropie/configs/pc/dosbox-staging.conf' delete_src=true
  restore_file '/opt/retropie/configs/pc/dosbox-SVN.conf' delete_src=true
  rm -rfv /opt/retropie/configs/pc/mapperfiles
}

remove() {
  sudo apt-get remove -y fluid-soundfont-gm
}

setup "${@}"
