#!/bin/bash

install() {
  sudo apt install -y libpoppler-cpp-dev
  sudo pip3 install python-poppler==0.2.2 numpy==1.21.1 evdev==1.4.0 pyudev==0.22.0 psutil==5.8.0
}

"${@}"
