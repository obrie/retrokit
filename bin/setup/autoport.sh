#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='autoport'
setup_module_desc='Automatic per-system/rom port selection based on input name'

install_dir="$retropie_dir/supplementary/autoport"

build() {
  # Copy manualkit to the retropie install path so that nothing depends
  # on retrokit being on the system
  dir_rsync '{lib_dir}/autoport/' "$install_dir/" as_sudo=true

  # Install xinput for x11-based applications
  sudo apt-get install -y xinput xserver-xorg-video-dummy
  sudo tee /etc/X11/dummy.conf >/dev/null <<EOF
Section "Device"
  Identifier "Card0"
  Driver "dummy"
EndSection
EOF
}

configure() {
  mkdir -p "$retropie_configs_dir/all/runcommand.d"
  ln -fsnv "$install_dir/runcommand" "$retropie_configs_dir/all/runcommand.d/autoport"
  ini_merge '{config_dir}/autoport/autoport.cfg' "$retropie_configs_dir/all/autoport.cfg" backup=false overwrite=true
}

restore() {
  rm -fv \
    "$retropie_configs_dir/all/autoport.cfg" \
    "$retropie_configs_dir/all/runcommand.d/autoport/"
}

remove() {
  sudo rm -rfv "$install_dir"
}

setup "${@}"
