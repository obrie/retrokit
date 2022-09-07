#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='launchkit'
setup_module_desc='launchkit install for optimizing game startup time when using launch images'

install_dir='/opt/retropie/supplementary/launchkit'

build() {
  # Copy launchkit to the retropie install path so that nothing depends
  # on retrokit being on the system
  sudo mkdir -p "$install_dir"
  sudo rsync -av --exclude '__pycache__/' --delete "$lib_dir/launchkit/" "$install_dir/"
}

configure() {
  ln -fsnv "$install_dir/runcommand" /opt/retropie/configs/all/runcommand.d/launchkit
}

restore() {
  rm -fv /opt/retropie/configs/all/runcommand.d/launchkit
}

remove() {
  sudo rm -rf "$install_dir"
}

setup "${@}"
