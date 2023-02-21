#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='retropie-runcommand'
setup_module_desc='runcommand hooks and configuration'

build() {
  file_cp '{ext_dir}/runcommand/onstart.sh' "$retropie_configs_dir/all/runcommand-onstart.sh" backup=false envsubst=false
  file_cp '{ext_dir}/runcommand/onlaunch.sh' "$retropie_configs_dir/all/runcommand-onlaunch.sh" backup=false envsubst=false
  file_cp '{ext_dir}/runcommand/onend.sh' "$retropie_configs_dir/all/runcommand-onend.sh" backup=false envsubst=false
  mkdir -p "$retropie_configs_dir/all/runcommand.d"
}

configure() {
  ini_merge '{config_dir}/runcommand/runcommand.cfg' "$retropie_configs_dir/all/runcommand.cfg"
}

restore() {
  restore_file "$retropie_configs_dir/all/runcommand.cfg" delete_src=true
}

remove() {
  rm -frv \
    "$retropie_configs_dir/all/runcommand-onstart.sh" \
    "$retropie_configs_dir/all/runcommand-onlaunch.sh" \
    "$retropie_configs_dir/all/runcommand-onend.sh" \
    "$retropie_configs_dir/all/runcommand.d"
}

setup "${@}"
