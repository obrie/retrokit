#!/bin/bash

install() {
  sudo pip3 install evdev==1.4.0 pyudev==0.22.0 psutil==5.8.0

  sudo apt remove libmupdf-dev
  wget https://mupdf.com/downloads/archive/mupdf-1.18.0-source.tar.gz
  tar -zxvf mupdf-1.18.0-source.tar.gz

  cd mupdf-1.18.0-source
  # replace files in mupdf source
  cp ../PyMuPDF/fitz/_config.h include/mupdf/fitz/config.h

  export CFLAGS="-fPIC"
  # install some prerequirement
  sudo apt install pkg-config python-dev

  make HAVE_X11=no HAVE_GLFW=no HAVE_GLUT=no prefix=/usr/local
  sudo make HAVE_X11=no HAVE_GLFW=no HAVE_GLUT=no prefix=/usr/local install

  cd ..

  rm -rf PyMuPDF
  git clone https://github.com/pymupdf/PyMuPDF.git
  cd PyMuPDF

  sudo python3 setup.py build
  sudo python3 setup.py install
}

"${@}"
