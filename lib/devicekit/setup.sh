#!/bin/bash

set -e

depends() {
  sudo pip3 install evdev~=1.6 pyudev~=0.24.0
}

remove() {
  sudo pip3 uninstall -y evdev pyudev
}

"${@}"
