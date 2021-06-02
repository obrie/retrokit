#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

install() {
  sudo systemctl enable ssh
  sudo systemctl start ssh
}

uninstall() {
  echo 'No uninstall for ssh.  Please do this manually.'
}

"${@}"
