#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

install() {
  # Benchmarking
  sudo apt install -y sysbench

  # Screen
  sudo apt install -y screen
  
  # Graphics
  sudo apt install -y mesa-utils
}

uninstall() {
  sudo apt remove -y mesa-utils screen sysbench
}

"${@}"
