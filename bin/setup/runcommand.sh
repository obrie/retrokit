#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

# Installs a helper for fixing terminal framebuffer issues
install_termfix() {
  mkdir $tmp_dir/termfix
  git clone --depth 1 https://github.com/hobbitalastair/termfix.git $tmp_dir/termfix
  pushd $tmp_dir/termfix
  make clean
  make
  sudo make install
  popd
  rm -rf $tmp_dir/termfix
}

install_configurations() {
  file_cp "$app_dir/bin/runcommand/onstart.sh" '/opt/retropie/configs/all/runcommand-onstart.sh'
  file_cp "$app_dir/bin/runcommand/onend.sh" '/opt/retropie/configs/all/runcommand-onend.sh'

  ini_merge "$config_dir/runcommand/runcommand.cfg" '/opt/retropie/configs/all/runcommand.cfg'
}

install() {
  install_termfix
  install_configurations
}

uninstall() {
  restore '/opt/retropie/configs/all/runcommand.cfg' delete_src=true
  restore '/opt/retropie/configs/all/runcommand-onstart.sh' delete_src=true
  restore '/opt/retropie/configs/all/runcommand-onend.sh' delete_src=true
  sudo rm /usr/bin/termfix
}

"${@}"
