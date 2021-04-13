#!/bin/bash

##############
# System: PC
# 
# Configs:
# * ~/.dosbox/dosbox-SVN.conf
##############

alias install_emulators_super=install_emulators
install_emulators() {
  install_emulators_super

  # Install emulators
  # sudo $HOME/RetroPie-Setup/retropie_packages.sh dosbox _binary_
  # sudo $HOME/RetroPie-Setup/retropie_packages.sh lr-dosbox-pure _binary_

  # Sound driver
  sudo apt install fluid-soundfont-gm

  # Set up [Gravis Ultrasound](https://retropie.org.uk/docs/PC/#install-gravis-ultrasound-gus):
}

