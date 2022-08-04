#!/bin/bash

set -e

depends() {
  # Python libs
  sudo pip3 install \
    psutil==5.8.0 \
    gpiozero==1.6.2
}

remove() {
  sudo pip3 uninstall -y psutil gpiozero
}

"${@}"
