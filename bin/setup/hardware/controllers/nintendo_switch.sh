#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../../common.sh"

setup_module_id='hardware/controllers/nintendo_switch'
setup_module_desc='Nintendo switch controller setup and configuration'

module_version=3.2

depends() {
  sudo apt-get install -y libevdev-dev
}

build() {
  build_kernel_module
  build_joycond
}

build_kernel_module() {
  if [ -d /var/lib/dkms/nintendo/$module_version ]; then
    echo 'hid-nintendo is already installed'
    return
  fi

  # Check out
  git clone --depth 1 https://github.com/nicman23/dkms-hid-nintendo "$tmp_ephemeral_dir/dkms-hid-nintendo"
  pushd "$tmp_ephemeral_dir/dkms-hid-nintendo"

  sudo dkms add .
  sudo dkms build nintendo -v $module_version
  sudo dkms install nintendo -v $module_version
}

build_joycond() {
  if [ -f /usr/bin/joycond ] && [ "$FORCE_UPDATE" != 'true' ]; then
    echo 'joycond is already installed'
    return
  fi

  git clone --depth 1 https://github.com/DanielOgorchock/joycond "$tmp_ephemeral_dir/joycond"
  pushd "$tmp_ephemeral_dir/joycond"

  cmake .
  sudo make install
}

configure() {
  sudo systemctl enable --now joycond
}

restore() {
  sudo systemctl disable --now joycond
}

remove() {
  # Remove all remnants of joycond
  sudo rm -rfv \
    /usr/bin/joycond \
    /lib/udev/rules.d/89-joycond.rules \
    /lib/udev/rules.d/72-joycond.rules \
    /etc/systemd/system/joycond.service \
    /etc/modules-load.d/joycond.conf \

  # Remove the nintendo kernel module
  sudo dkms uninstall nintendo -v $module_version
  sudo dkms remove nintendo/$module_version --all

  sudo apt-get remove -y libevdev-dev
}

setup "${@}"
