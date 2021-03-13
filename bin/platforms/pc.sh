#!/bin/bash

##############
# Emulator: PC
# 
# Configs:
# * ~/.dosbox/dosbox-SVN.conf
##############

set -e

# Install emulators
sudo ~/RetroPie-Setup/retropie_packages.sh dosbox _binary_
sudo ~/RetroPie-Setup/retropie_packages.sh lr-dosbox-pure _binary_

# Sound driver
sudo apt install fluid-soundfont-gm

# Set up [Gravis Ultrasound](https://retropie.org.uk/docs/PC/#install-gravis-ultrasound-gus):
