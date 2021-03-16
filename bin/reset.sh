#!/bin/bash

##############
# Reset the system
##############

set -ex

usage() {
  echo "usage: $0"
  exit 1
}

# Reset inputs
reset_inputs() {
  sudo ~/RetroPie-Setup/retropie_packages.sh emulationstation init_input
}

if [[ $# -ne 0 ]]; then
  usage
fi

reset_inputs
