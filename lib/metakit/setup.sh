#!/bin/bash

set -e

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

depends() {
  sudo pip3 install -r "$dir/requirements.txt"
}

remove() {
  command -v pip3 >/dev/null && sudo pip3 uninstall -y -r "$dir/requirements.txt"
}

"${@}"
