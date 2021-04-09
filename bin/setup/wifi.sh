#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

install() {
  # Remove existing networks

  # Add new networks
  echo 'No install for wifi'
}

uninstall() {
  # no-op
  echo 'No uninstall for wifi'
}

"${@}"
