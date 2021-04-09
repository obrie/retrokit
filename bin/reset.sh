#!/bin/bash

##############
# Reset the system
##############

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. $dir/common.sh

usage() {
  echo "usage: $0"
  exit 1
}

# Reset inputs
reset_inputs() {
  sudo $HOME/RetroPie-Setup/retropie_packages.sh emulationstation init_input
}

if [[ $# -ne 0 ]]; then
  usage
fi

reset_inputs
