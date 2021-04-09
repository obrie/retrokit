#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup() {
  local argon_bin="$tmp_dir/argon1.sh"

  download 'https://download.argon40.com/argon1.sh' "$argon_bin"
  bash "$argon_bin"
  rm "$argon_bin"
}

setup
