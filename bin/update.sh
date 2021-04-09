#!/bin/bash

##############
# Update the system
##############

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. $dir/common.sh

usage() {
  echo "usage: $0 [command]"
  exit 1
}

# Update RetroPie-Setup
update_retropie_setup() {
  pushd $HOME/RetroPie-Setup
  git pull --ff-only
  popd
  sudo $HOME/RetroPie-Setup/retropie_packages.sh setup post_update
  clear
}

# Update system
update_system() {
  sudo apt update
  sudo apt-get -y dist-upgrade
  # sudo apt full-upgrade
}

update_packages() {
  # Update packages
  sudo $HOME/RetroPie-Setup/retropie_packages.sh setup update_packages
}

update_all() {
  update_retropie_setup
  update_system
  update_packages
}

if [[ $# -gt 1 ]]; then
  usage
fi

target=${1:-all}
"update_$target"
