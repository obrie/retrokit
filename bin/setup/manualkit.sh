#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='manualkit'
setup_module_desc='manualkit install and configuration for viewing game manuals'

install_dir='/opt/retropie/supplementary/manualkit'

depends() {
  "$bin_dir/manualkit/setup.sh" depends
}

build() {
  # Copy manualkit to the retropie install path so that nothing depends
  # on retrokit being on the system
  sudo mkdir -p "$install_dir"
  sudo rsync -av --exclude '__pycache__/' --delete "$bin_dir/manualkit/" "$install_dir/"
}

configure() {
  ini_merge '{config_dir}/manualkit/manualkit.conf' '/opt/retropie/configs/all/manualkit.conf' backup=false overwrite=true
}

remove() {
  rm -rfv "$install_dir" '/opt/retropie/configs/all/manualkit.conf'

  # Only remove python modules uniquely used by manualkit
  sudo pip3 uninstall -y \
    psutil \
    PyMuPDF
}

setup "${@}"
