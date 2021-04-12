#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

install() {
  sudo apt update
  sudo apt -y full-upgrade
}

uninstall() {
  echo 'No uninstall for upgrades'
}

"${@}"
