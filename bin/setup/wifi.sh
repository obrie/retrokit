#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

install() {
  # Remove existing networks

  # Add new networks
}

uninstall() {
  # no-op
}

"${@}"
