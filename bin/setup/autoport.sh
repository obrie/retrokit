#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='autoport'
setup_module_desc='Automatic per-system/rom port selection based on input name'

configure() {
  __configure_autoport
  __configure_runcommand
}

__configure_autoport() {
  ini_merge '{config_dir}/autoport/autoport.cfg' '/opt/retropie/configs/all/autoport.cfg' backup=false overwrite=true
}

# Install emulationstation hooks
__configure_runcommand() {
  __restore_runcommand

  mkdir -pv /opt/retropie/configs/all/runcommand.d/autoport/
  while read hook_filename; do
    local hook=${hook_filename%.*}
    file_cp "{config_dir}/autoport/runcommand/$hook.sh" "/opt/retropie/configs/all/runcommand.d/autoport/$hook.sh" backup=false envsubst=false
  done < <(each_path '{config_dir}/autoport/runcommand' ls '{}' | uniq)
}

restore() {
  rm -rfv /opt/retropie/configs/all/autoport.cfg

  __restore_runcommand
}

__restore_runcommand() {
  rm -rfv /opt/retropie/configs/all/runcommand.d/autoport/
}

setup "${@}"
