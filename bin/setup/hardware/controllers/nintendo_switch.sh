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
  if dkms status nintendo/$module_version | grep -q installed; then
    echo 'hid-nintendo is already installed'
    return
  fi

  # Check out
  local repo_dir=$(mktemp -d -p "$tmp_ephemeral_dir")
  git clone --depth 1 https://github.com/nicman23/dkms-hid-nintendo "$repo_dir"
  pushd "$repo_dir"

  sudo dkms add .
  sudo dkms build nintendo -v $module_version
  sudo dkms install nintendo -v $module_version
}

build_joycond() {
  if [ -f /usr/bin/joycond ] && [ "$FORCE_UPDATE" != 'true' ]; then
    echo 'joycond is already installed'
    return
  fi

  # Check out
  local repo_dir=$(mktemp -d -p "$tmp_ephemeral_dir")
  git clone --depth 1 https://github.com/DanielOgorchock/joycond "$repo_dir"
  pushd "$repo_dir"

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
  if dkms status nintendo/$module_version | grep -q installed; then
    sudo dkms remove nintendo/$module_version --all
  fi
  sudo rm -rfv "/usr/src/nintendo-$module_version"

  if lsmod | grep -q nintendo; then
    rmmod nintendo
  fi

  sudo apt-get remove -y libevdev-dev
  sudo apt-get autoremove --purge -y
}

setup "${@}"
