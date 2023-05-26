#!/bin/bash

set -e

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

depends() {
  # Python libs (TODO: Add dependency on devicekit)
  sudo pip3 install -r "$dir/requirements.txt"
}

remove() {
  command -v pip3 >/dev/null && sudo pip3 uninstall -r "$dir/requirements.txt"
}

"${@}"
