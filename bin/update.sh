#!/bin/bash

##############
# Update the system
##############

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/common.sh"

usage() {
  echo "usage: $0 <command> [command_args]"
  exit 1
}

# Update system
update_system() {
  sudo apt update
  sudo apt-get -y dist-upgrade
}

# Update RetroPie-Setup and packages
update_retropie() {
  update_retropie_setup
  update_retropie_packages
}

# Update RetroPie-Setup
update_retropie_setup() {
  pushd $HOME/RetroPie-Setup
  git pull --ff-only
  popd
  sudo $HOME/RetroPie-Setup/retropie_packages.sh setup post_update
  clear
}

# Update packages.  By default, any default configuration changes made to
# emulators by RetroPie configurations will *not* be picked up.  You must
# explicitly decide to accept those by running `update_emulator_configs`.
update_retropie_packages() {
  if [ $# -eq 0 ]; then
    sudo $HOME/RetroPie-Setup/retropie_packages.sh setup update_packages
  else
    for package in "$@"; do
      sudo $HOME/RetroPie-Setup/retropie_packages.sh "$package" _update_
    done
  fi
}

if [[ $# -eq 0 ]]; then
  usage
fi

"update_$1" "${@:2}"
