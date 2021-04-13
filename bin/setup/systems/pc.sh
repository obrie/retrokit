#!/bin/bash

##############
# System: PC
# 
# Configs:
# * ~/.dosbox/dosbox-SVN.conf
##############

save_function install_emulators install_emulators_super
install_emulators() {
  install_emulators_super

  # Sound driver
  sudo apt install fluid-soundfont-gm
}
