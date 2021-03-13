#!/bin/bash

##############
# Image a new SD card
##############

set -e

usage() {
  echo "usage: $0 [DEVICE]"
  exit 1
}

if [[ $# -ne 1 ]]; then
  usage
fi

retropie_version=4.7.1
raspbian_version=buster
rpi_version=rpi4_400
device=$1

# Download Retropie
wget https://github.com/RetroPie/RetroPie-Setup/releases/download/$retropie_version/retropie-$raspbian_version-$retropie_version-$rpi_version.img.gz -O /tmp/retropie.img.gz

# Copy the image
gunzip --stdout /tmp/retropie.img.gz | sudo dd bs=4M of=$device
