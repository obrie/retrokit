#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

# Installs a helper for fixing terminal framebuffer issues
install_termfix() {
  local version="$(cat /etc/termfix.version || true)"
  if [ ! `command -v termfix` ] || has_newer_commit https://github.com/hobbitalastair/termfix "$version"; then
    # Check out
    rm -rf "$tmp_dir/termfix"
    git clone --depth 1 https://github.com/hobbitalastair/termfix.git "$tmp_dir/termfix"
    pushd "$tmp_dir/termfix"
    version=$(git rev-parse HEAD)

    # Compile
    make
    sudo make install
    echo "$version" | sudo tee /etc/termfix.version

    # Clean up
    popd
    rm -rf "$tmp_dir/termfix"
  else
    echo "termfix is already the newest version ($version)"
  fi
}

install_configurations() {
  file_cp "$app_dir/bin/runcommand/onstart.sh" '/opt/retropie/configs/all/runcommand-onstart.sh' envsubst=false
  file_cp "$app_dir/bin/runcommand/onend.sh" '/opt/retropie/configs/all/runcommand-onend.sh' envsubst=false

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
  sudo rm -f /usr/bin/termfix /etc/termfix.version
}

"${@}"
