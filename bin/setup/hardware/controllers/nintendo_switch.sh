#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../../common.sh"

setup_module_id='hardware/controllers/nintendo_switch'
setup_module_desc='Nintendo switch controller setup and configuration'

module_version=3.2

build() {
  if [ -d /var/lib/dkms/nintendo/$module_version ]; then
    return
  fi

  # Check out
  rm -rf "$tmp_ephemeral_dir/dkms-hid-nintendo"
  git clone --depth 1 https://github.com/nicman23/dkms-hid-nintendo "$tmp_ephemeral_dir/dkms-hid-nintendo"
  pushd "$tmp_ephemeral_dir/dkms-hid-nintendo"

  sudo dkms add .
  sudo dkms build nintendo -v $module_version
  sudo dkms install nintendo -v $module_version
}

remove() {
  sudo dkms uninstall nintendo -v $module_version
  sudo dkms remove nintendo/$module_version --all
}

setup "${@}"
