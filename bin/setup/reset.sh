#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup() {
  # Reset inputs
  sudo $HOME/RetroPie-Setup/retropie_packages.sh emulationstation init_input
}

setup
