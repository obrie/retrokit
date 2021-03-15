#!/bin/bash

##############
# Platform: PC
# 
# Configs:
# * ~/.dosbox/dosbox-SVN.conf
##############

set -ex

APP_DIR=$(cd "$( dirname "$0" )/../.." && pwd)
CONFIG_DIR="$APP_DIR/platforms/config/c64"

# Install emulators
sudo ~/RetroPie-Setup/retropie_packages.sh dosbox _binary_
sudo ~/RetroPie-Setup/retropie_packages.sh lr-dosbox-pure _binary_

# Sound driver
sudo apt install fluid-soundfont-gm

# Set up [Gravis Ultrasound](https://retropie.org.uk/docs/PC/#install-gravis-ultrasound-gus):
