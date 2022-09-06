#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='runcommand'
setup_module_desc='runcommand hooks and configuration'

runcommand_apps_path='/opt/retropie/configs/all/runcommand.d'

build() {
  file_cp '{ext_dir}/runcommand/onstart.sh' /opt/retropie/configs/all/runcommand-onstart.sh backup=false envsubst=false
  file_cp '{ext_dir}/runcommand/onlaunch.sh' /opt/retropie/configs/all/runcommand-onlaunch.sh backup=false envsubst=false
  file_cp '{ext_dir}/runcommand/onend.sh' /opt/retropie/configs/all/runcommand-onend.sh backup=false envsubst=false
}

configure() {
  ini_merge '{config_dir}/runcommand/runcommand.cfg' /opt/retropie/configs/all/runcommand.cfg
}

restore() {
  restore_file '/opt/retropie/configs/all/runcommand.cfg' delete_src=true
}

remove() {
  rm -frv \
    /opt/retropie/configs/all/runcommand-onstart.sh \
    /opt/retropie/configs/all/runcommand-onlaunch.sh \
    /opt/retropie/configs/all/runcommand-onend.sh \
    /opt/retropie/configs/all/runcommand.d
}

setup "${@}"
