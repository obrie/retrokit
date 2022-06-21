#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../../common.sh"

setup_module_id='hardware/cases/nespi'
setup_module_desc='NesPi safe shutdown scripts'

depends() {
  sudo pip3 install psutil==5.8.0 gpiozero==1.6.2
}

build() {
  file_cp '{config_dir}/cases/nespi/nespi.service' /etc/systemd/system/nespi.service as_sudo=true backup=false
  file_cp '{config_dir}/cases/nespi/safe_shutdown.py' /opt/RetroFlag/safe_shutdown.py as_sudo=true backup=false
}

configure() {
  sudo systemctl enable --now nespi.service
}

restore() {
  sudo systemctl stop nespi.service || true
  sudo systemctl disable nespi.service || true
}

remove() {
  sudo rm -fv \
    /opt/RetroFlag/safe_shutdown.py \
    /etc/systemd/system/nespi.service

  sudo pip3 uninstall -y gpiozero
}

setup "${@}"
