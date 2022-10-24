#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='autoport'
setup_module_desc='Automatic per-system/rom port selection based on input name'

install_dir='/opt/retropie/supplementary/autoport'

build() {
  # Copy manualkit to the retropie install path so that nothing depends
  # on retrokit being on the system
  sudo mkdir -p "$install_dir"
  sudo rsync -av --exclude '__pycache__/' --delete "$lib_dir/autoport/" "$install_dir/"
}

configure() {
  mkdir -p /opt/retropie/configs/all/runcommand.d
  ln -fsnv "$install_dir/runcommand" /opt/retropie/configs/all/runcommand.d/autoport
  ini_merge '{config_dir}/autoport/autoport.cfg' '/opt/retropie/configs/all/autoport.cfg' backup=false overwrite=true
}

restore() {
  rm -fv \
    /opt/retropie/configs/all/autoport.cfg \
    /opt/retropie/configs/all/runcommand.d/autoport/
}

remove() {
  rm -rfv /opt/retropie/supplementary/autoport/
}

setup "${@}"
