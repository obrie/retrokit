#!/bin/bash

set -e

depends() {
  sudo pip3 install evdev==1.4.0 pyudev==0.22.0
}

remove() {
  sudo pip3 uninstall -y evdev pyudev
}

"${@}"
