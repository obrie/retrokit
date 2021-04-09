#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

install() {
  # Install apt key
  curl https://www.linux-projects.org/listing/uv4l_repo/lpkey.asc | sudo apt-key add -
  echo 'deb http://www.linux-projects.org/listing/uv4l_repo/raspbian/stretch stretch main' | sudo tee /etc/apt/sources.list.d/uv4l.list

  # Install sever
  sudo apt install -y uv4luv4l-server uv4l-webrtc uv4l-raspidisp uv4l-raspidisp-extras

  # Enable WebRTC access
  uv4l --auto-video_nr --driver raspidisp --server-option '--enable-webrtc=yes'
}

uninstall() {
  sudo apt remove -y uv4luv4l-server uv4l-webrtc uv4l-raspidisp uv4l-raspidisp-extras
}

"${@}"
