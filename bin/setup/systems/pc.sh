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

  # Sound driver
  sudo apt install fluid-soundfont-gm
}

