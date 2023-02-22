#!/bin/bash

system='c64'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

setup_module_id='system/c64/tools'
setup_module_desc='Tools for processing c64 NIB files'

opencbm_version=0.4.99.104
opencbm_version_name=${opencbm_version//./_}

depends() {
  if [ ! `command -v cbmcopy` ] || ! cbmcopy --version | grep "$opencbm_version"; then
    sudo apt-get install -y libusb-dev libncurses5-dev tcpser cc65

    local opencbm_dir=$(mktemp -d -p "$tmp_ephemeral_dir")
    wget "https://github.com/OpenCBM/OpenCBM/archive/refs/tags/v$opencbm_version_name.zip" -O "$opencbm_dir/opencbm.zip"
    unzip "$opencbm_dir/opencbm.zip" -d "$opencbm_dir"

    pushd "$opencbm_dir/OpenCBM-$opencbm_version_name"
    make -f LINUX/Makefile opencbm plugin-xum1541
    sudo make -f LINUX/Makefile install install-plugin-xum1541
    popd
  fi
}

build() {
  if [ ! `command -v nibconv` ]; then
    local nibtools_dir=$(mktemp -d -p "$tmp_ephemeral_dir")
    git clone --depth 1 https://github.com/OpenCBM/nibtools.git "$nibtools_dir"
    pushd "$nibtools_dir"

    make -f GNU/Makefile linux
    sudo cp \
      nibconv \
      nibread \
      nibrepair \
      nibscan \
      nibsrqtest \
      nibwrite \
      /usr/local/bin

    popd
  fi
}

remove() {
  # Remove nibtools
  sudo rm -fv \
    /usr/local/bin/nibconv \
    /usr/local/bin/nibread \
    /usr/local/bin/nibrepair \
    /usr/local/bin/nibscan \
    /usr/local/bin/nibsrqtest \
    /usr/local/bin/nibwrite

  if [ `command -v cbmcopy` ]; then
    # It's easiest for us to just use the uninstall from opencbm's Makefile
    local opencbm_dir=$(mktemp -d -p "$tmp_ephemeral_dir")
    wget "https://github.com/OpenCBM/OpenCBM/archive/refs/tags/v$opencbm_version_name.zip" -O "$opencbm_dir/opencbm.zip"
    unzip "$opencbm_dir/opencbm.zip" -d "$opencbm_dir"

    pushd "$opencbm_dir/OpenCBM-$opencbm_version_name"
    sudo make -f LINUX/Makefile uninstall
    popd
  fi

  sudo apt-get remove -y libncurses5-dev libusb-dev tcpser cc65
}

setup "${@}"
