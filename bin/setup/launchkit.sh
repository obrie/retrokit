#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='launchkit'
setup_module_desc='launchkit install for optimizing game startup time when using launch images'

install_dir="$retropie_dir/supplementary/launchkit"

build() {
  # Copy launchkit to the retropie install path so that nothing depends
  # on retrokit being on the system
  dir_rsync '{lib_dir}/launchkit/' "$install_dir/" as_sudo=true
}

configure() {
  mkdir -p "$retropie_configs_dir/all/runcommand.d"
  ln -fsnv "$install_dir/runcommand" "$retropie_configs_dir/all/runcommand.d/launchkit"
}

restore() {
  rm -fv "$retropie_configs_dir/all/runcommand.d/launchkit"
}

remove() {
  sudo rm -rf "$install_dir"
}

setup "${@}"
