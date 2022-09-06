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
  restore

  mkdir -pv /opt/retropie/configs/all/runcommand.d/launchkit/
  while read hook_filename; do
    local hook=${hook_filename%.*}
    file_cp "{lib_dir}/launchkit/runcommand/$hook.sh" "/opt/retropie/configs/all/runcommand.d/launchkit/$hook.sh" backup=false envsubst=false
  done < <(each_path '{config_dir}/launchkit/runcommand' ls '{}' | uniq)
}

restore() {
  rm -rfv /opt/retropie/configs/all/runcommand.d/launchkit/
}

setup "${@}"
