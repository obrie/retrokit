#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../../common.sh"

setup_module_id='hardware/cases/nespi'
setup_module_desc='NesPi safe shutdown scripts'

build() {
  download 'https://github.com/RetroFlag/retroflag-picase/raw/master/RetroFlag_pw_io.dtbo' /boot/overlays/RetroFlag_pw_io.dtbo as_sudo=true
  download 'https://github.com/RetroFlag/retroflag-picase/raw/master/SafeShutdown.py' /opt/RetroFlag/SafeShutdown.py as_sudo=true
  file_cp '{config_dir}/cases/nespi/nespi.service' /etc/systemd/system/nespi.service as_sudo=true
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
    /opt/RetroFlag/SafeShutdown.py \
    /etc/systemd/system/nespi.service
}

setup "${@}"
