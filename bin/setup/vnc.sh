#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

install() {
  # Install dependencies
  sudo apt install -y libvncserver-dev libconfig++-dev

  local version="$(cat /etc/dispmanx_vncserver.version 2>/dev/null || true)"
  if [ ! `command -v dispmanx_vncserver` ] || has_newer_commit https://github.com/patrikolausson/dispmanx_vnc "$version"; then
    # Check out
    rm -rf "$tmp_ephemeral_dir/dispmanx_vnc"
    git clone --depth 1 https://github.com/patrikolausson/dispmanx_vnc "$tmp_ephemeral_dir/dispmanx_vnc"
    pushd "$tmp_ephemeral_dir/dispmanx_vnc"
    version=$(git rev-parse HEAD)

    # Apply patches
    patch -p1 < "$config_dir/vnc/0001-fix-keyboard.patch"

    # Compile
    make

    # Copy to system
    sudo systemctl stop dispmanx_vncserver || true
    sudo cp dispmanx_vncserver /usr/bin
    sudo chmod +x /usr/bin/dispmanx_vncserver

    configure

    # Install service
    sudo systemctl daemon-reload
    sudo systemctl enable dispmanx_vncserver
    sudo systemctl start dispmanx_vncserver
    echo "$version" | sudo tee /etc/dispmanx_vncserver.version

    # Clean up
    popd
    rm -rf "$tmp_ephemeral_dir/dispmanx_vnc"
  else
    echo "dispmanx_vnc already the newest version ($version)"
  fi
}

configure() {
  file_cp "$config_dir/vnc/dispmanx_vncserver.conf" /etc/dispmanx_vncserver.conf as_sudo=true
  file_cp "$config_dir/vnc/dispmanx_vncserver.service" /etc/systemd/system/dispmanx_vncserver.service envsubst=false as_sudo=true
}

restore() {
  restore_file /etc/dispmanx_vncserver.conf as_sudo=true delete_src=true
  restore_file /etc/systemd/system/dispmanx_vncserver.service as_sudo=true delete_src=true
}

uninstall() {
  restore
  
  sudo systemctl stop dispmanx_vncserver || true
  sudo systemctl disable dispmanx_vncserver || true
  sudo rm -fv \
    /etc/dispmanx_vncserver.version \
    /etc/systemd/system/dispmanx_vncserver.service \
    /etc/dispmanx_vncserver.conf \
    /usr/bin/dispmanx_vncserver
}

"${@}"
