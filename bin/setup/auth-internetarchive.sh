#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='auth-internetarchive'
setup_module_desc='Authentication configuration for archive.org'

ia_bin="/usr/local/bin/ia"

depends() {
  # Install CLI
  sudo pip3 install internetarchive~=3.3
}

configure() {
  if [ -z "$IA_USERNAME" ] || [ -z "$IA_PASSWORD" ]; then
    return
  fi

  ia configure -u "$IA_USERNAME" -p "$IA_PASSWORD"
}

restore() {
  sudo rm -fv "$home/.config/internetarchive/ia.ini"
}

remove() {
  [ -z $(command -v pip3) ] || sudo pip3 uninstall -y internetarchive
}

setup "${@}"
