#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='powerkit'
setup_module_desc='Hardware safe shutdown scripts'

install_dir="$retropie_dir/supplementary/powerkit"

depends() {
  "$lib_dir/devicekit/setup.sh" depends
  "$lib_dir/powerkit/setup.sh" depends

  dir_rsync '{lib_dir}/devicekit/' "$retropie_dir/supplementary/devicekit/" as_sudo=true
}

build() {
  file_cp '{config_dir}/powerkit/powerkit.service' /etc/systemd/system/powerkit.service as_sudo=true backup=false

  # Copy powerkit to the retropie install path so that nothing depends
  # on retrokit being on the system
  dir_rsync '{lib_dir}/powerkit/' "$install_dir/" as_sudo=true
}

configure() {
  ini_merge '{config_dir}/powerkit/powerkit.cfg' "$retropie_configs_dir/all/powerkit.cfg" backup=false overwrite=true
  sudo systemctl enable powerkit.service

  # Restart
  sudo systemctl restart powerkit
}

restore() {
  sudo systemctl stop powerkit.service || true
  sudo systemctl disable powerkit.service || true
}

remove() {
  sudo rm -rfv \
    "$install_dir" \
    "$retropie_configs_dir/all/powerkit.cfg" \
    /etc/systemd/system/powerkit.service

  command -v pip3 >/dev/null && sudo pip3 uninstall -y gpiozero
}

setup "${@}"
