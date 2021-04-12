#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

install() {
  # Install apt key
  curl https://www.linux-projects.org/listing/uv4l_repo/lpkey.asc | sudo apt-key add -
  echo 'deb http://www.linux-projects.org/listing/uv4l_repo/raspbian/stretch stretch main' | sudo tee /etc/apt/sources.list.d/uv4l.list

  # Install sever
  sudo apt install -y uv4l uv4l-server uv4l-webrtc uv4l-raspidisp uv4l-raspidisp-extras

  # Configure server
  ini_merge "$config_dir/vnc/uv4l-raspidisp.conf" '/etc/uv4l/uv4l-raspidisp.conf' as_sudo=true
  sudo systemctl restart uv4l_raspidisp
}

uninstall() {
  sudo apt remove -y uv4l uv4l-server uv4l-webrtc uv4l-raspidisp uv4l-raspidisp-extras
}

"${@}"
