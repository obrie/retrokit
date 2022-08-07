#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='powerkit'
setup_module_desc='Hardware safe shutdown scripts'

install_dir='/opt/retropie/supplementary/powerkit'

depends() {
  "$bin_dir/powerkit/setup.sh" depends
}

build() {
  file_cp '{config_dir}/powerkit/powerkit.service' /etc/systemd/system/powerkit.service as_sudo=true backup=false

  # Copy powerkit to the retropie install path so that nothing depends
  # on retrokit being on the system
  sudo mkdir -p "$install_dir"
  sudo rsync -av --exclude '__pycache__/' --delete "$bin_dir/powerkit/" "$install_dir/"
}

configure() {
  CASE_MODEL="$(setting '.hardware.case.model')" ini_merge '{config_dir}/powerkit/powerkit.cfg' '/opt/retropie/configs/all/powerkit.cfg' backup=false overwrite=true
  sudo systemctl enable --now powerkit.service
}

restore() {
  sudo systemctl stop powerkit.service || true
  sudo systemctl disable powerkit.service || true
}

remove() {
  rm -rfv \
    "$install_dir" \
    /opt/retropie/configs/all/powerkit.cfg \
    /etc/systemd/system/powerkit.service

  sudo pip3 uninstall -y gpiozero
}

setup "${@}"
