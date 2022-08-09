#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='runcommand'
setup_module_desc='runcommand hooks and configuration'

runcommand_apps_path='/opt/retropie/configs/all/runcommand.d'

build() {
  file_cp '{bin_dir}/runcommand/onstart.sh' /opt/retropie/configs/all/runcommand-onstart.sh backup=false envsubst=false
  file_cp '{bin_dir}/runcommand/onlaunch.sh' /opt/retropie/configs/all/runcommand-onlaunch.sh backup=false envsubst=false
  file_cp '{bin_dir}/runcommand/onend.sh' /opt/retropie/configs/all/runcommand-onend.sh backup=false envsubst=false

  # Copy enabled runcommand apps
  while read runcommand_app; do
    # Reset the app's directory
    mkdir -p "$runcommand_apps_path/$runcommand_app"
    rm -rf "$runcommand_apps_path/$runcommand_app/"*

    # Copy over the app's files
    each_path "{bin_dir}/runcommand/$runcommand_app" cp -Rv '{}' "$runcommand_apps_path/"
  done < <(setting '.runcommand .scripts[]')
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
