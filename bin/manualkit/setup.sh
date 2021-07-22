#!/bin/bash

install() {
  sudo apt install -y libpoppler-cpp-dev
  sudo pip3 install python-poppler==0.2.2 numpy==1.21.1 keyboard==0.13.5 psutil==5.8.0
}

"${@}"
