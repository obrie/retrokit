#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

install() {
  sudo systemctl enable ssh
  sudo systemctl start ssh
}

uninstall() {
  sudo systemctl stop ssh || true
  sudo systemctl disable ssh || true
}

"${@}"
