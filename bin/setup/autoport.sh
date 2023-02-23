#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='autoport'
setup_module_desc='Automatic per-system/rom port selection based on input name'

install_dir="$retropie_dir/supplementary/autoport"

build() {
  # Copy manualkit to the retropie install path so that nothing depends
  # on retrokit being on the system
  dir_rsync '{lib_dir}/autoport/' "$install_dir/" as_sudo=true
}

configure() {
  mkdir -p "$retropie_configs_dir/all/runcommand.d"
  ln -fsnv "$install_dir/runcommand" "$retropie_configs_dir/all/runcommand.d/autoport"
  ini_merge '{config_dir}/autoport/autoport.cfg' "$retropie_configs_dir/all/autoport.cfg" backup=false overwrite=true
}

restore() {
  rm -rfv \
    "$retropie_configs_dir/all/autoport.cfg" \
    "$retropie_configs_dir/all/runcommand.d/autoport/"
}

remove() {
  rm -rfv "$install_dir"
}

setup "${@}"
