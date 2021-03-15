#!/bin/bash

set -ex

##############
# Update the system
##############

# Update RetroPie-Setup
update_retropie_setup() {
  pushd ~/RetroPie-Setup
  git pull --ff-only
  popd
  sudo ~/RetroPie-Setup/retropie_packages.sh setup post_update
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
  sudo ~/RetroPie-Setup/retropie_packages.sh setup update_packages
}

update_retropie_setup
update_system
update_packages
