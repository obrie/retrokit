#!/bin/bash

##############
# Platform: PC
# 
# Configs:
# * ~/.dosbox/dosbox-SVN.conf
##############

DIR=$( dirname "$0" )
. $DIR/common.sh

PLATFORM="nes"
CONFIG_DIR="$APP_DIR/config/platforms/$PLATFORM"
SETTINGS_FILE="$CONFIG_DIR/settings.json"

setup() {
  # Install emulators
  sudo ~/RetroPie-Setup/retropie_packages.sh dosbox _binary_
  sudo ~/RetroPie-Setup/retropie_packages.sh lr-dosbox-pure _binary_

  # Sound driver
  sudo apt install fluid-soundfont-gm

  # Set up [Gravis Ultrasound](https://retropie.org.uk/docs/PC/#install-gravis-ultrasound-gus):
}

download() {
  # Download according to settings file
  download_platform "$PLATFORM"

  # Additional platform-specific logic
  # https://github.com/Voljega/ExoDOSConverter
}

if [[ $# -lt 1 ]]; then
  usage
fi

command="$1"
shift
"$command" "$@"
