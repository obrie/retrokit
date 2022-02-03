#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

ia_bin="/usr/local/bin/ia"

install() {
  # Install CLI
  sudo pip3 install internetarchive==2.0.3
  configure
}

configure() {
  # Login
  ia configure -u "$IA_USERNAME" -p "$IA_PASSWORD"
}

uninstall() {
  sudo pip3 uninstall -y internetarchive
}

"${@}"
