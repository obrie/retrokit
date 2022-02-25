#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='auth-internetarchive'
setup_module_desc='Authentication configuration for archive.org'

ia_bin="/usr/local/bin/ia"

depends() {
  # Install CLI
  sudo pip3 install internetarchive==2.0.3
}

configure() {
  # Login
  ia configure -u "$IA_USERNAME" -p "$IA_PASSWORD"
}

restore() {
  sudo rm -fv "$HOME/.config/ia.ini"
}

remove() {
  sudo pip3 uninstall -y internetarchive
}

setup "${@}"
