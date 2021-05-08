#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

# Download roms from a remote source
install() {
  romkit_cli install --log-level DEBUG
}

uninstall() {
  echo 'No uninstall for roms'
}

"$1" "${@:3}"
