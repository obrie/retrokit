#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

install() {
  $dir/../update.sh
}

uninstall() {
  echo 'No uninstall for upgrades'
}

"${@}"
