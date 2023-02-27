#!/bin/bash

set -e

depends() {
  # Python libs
  sudo pip3 install \
    psutil~=5.8 \
    gpiozero~=1.6.2

  # TODO: Add dependency on devicekit here
}

remove() {
  command -v pip3 >/dev/null && sudo pip3 uninstall -y psutil gpiozero
}

"${@}"
