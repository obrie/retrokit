#!/bin/bash

##############
# Image a new SD card
##############

set -ex

usage() {
  echo "usage: $0 <DEVICE>"
  exit 1
}

create() {
  device=$1
  retropie_version=4.7.1
  raspbian_version=buster
  rpi_version=rpi4_400

  # Download Retropie
  wget https://github.com/RetroPie/RetroPie-Setup/releases/download/$retropie_version/retropie-$raspbian_version-$retropie_version-$rpi_version.img.gz -O /tmp/retropie.img.gz

  # Copy the image
  gunzip --stdout /tmp/retropie.img.gz | sudo dd bs=4M of=$device
}

if [[ $# -ne 1 ]]; then
  usage
fi

create $1
