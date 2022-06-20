#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../../common.sh"

setup_module_id='hardware/cases/nespi'
setup_module_desc='NesPi safe shutdown scripts'

depends() {
  sudo pip3 install psutil==5.8.0 gpiozero==1.6.2
}

build() {
  download 'https://github.com/RetroFlag/retroflag-picase/raw/master/RetroFlag_pw_io.dtbo' /boot/overlays/RetroFlag_pw_io.dtbo as_sudo=true
  file_cp '{config_dir}/cases/nespi/nespi.service' /etc/systemd/system/nespi.service as_sudo=true
  file_cp '{config_dir}/cases/nespi/safe_shutdown.py' /opt/RetroFlag/safe_shutdown.py as_sudo=true
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
    /boot/overlays/RetroFlag_pw_io.dtbo \
    /opt/RetroFlag/safe_shutdown.py \
    /etc/systemd/system/nespi.service

  sudo pip3 uninstall -y gpiozero
}

setup "${@}"
