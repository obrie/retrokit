#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

install() {
  # PIP
  sudo apt install -y python3-pip

  # Ini editor
  sudo pip3 install crudini==0.9.3

  # Env editor
  download 'https://raw.githubusercontent.com/bashup/dotenv/d71c9d786fe193f43f1cb57c6b4a152ebb01ba60/dotenv' '/usr/local/bin/dotenv' as_sudo=true

  # JSON reader
  sudo apt install -y jq
}

uninstall() {
  sudo apt remove -y jq
  sudo rm -f /usr/local/bin/dotenv
  sudo pip3 uninstall -y crudini
  sudo apt remove -y python3-pip
}

"${@}"
