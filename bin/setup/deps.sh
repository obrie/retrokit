#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup() {
  # Ini editor
  sudo pip3 install crudini

  # Env editor
  download 'https://raw.githubusercontent.com/bashup/dotenv/master/dotenv' "$tmp_dir/dotenv"

  # JSON reader
  sudo apt install -y jq
}

setup
