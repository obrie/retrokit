#!/bin/bash

install() {
  sudo apt install -y libpoppler-cpp-dev
  sudo pip3 install -y python-poppler numpy keyboard
}

"${@}"
