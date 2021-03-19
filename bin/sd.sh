#!/bin/bash

##############
# SD Card management
##############

set -ex

DIR=$(dirname "$0")
APP_DIR=$(cd "$DIR/.." && pwd)

usage() {
  echo "usage: $0 <create|backup|restore> <device>"
  exit 1
}

restore() {
  device=$1
  gunzip --stdout "$APP_DIR/backups/stable/sd-retropie.iso.gz" | sudo dd bs=4M of=$device
}

backup() {
  device=$1
  sudo dd bs=4M if=$device | gzip | dd bs=4M of="$APP_DIR/backups/sd-retropie.iso.gz"
}

create() {
  device=$1
  retropie_version=4.7.1
  raspbian_version=buster
  rpi_version=rpi4_400
  image_file=/tmp/retropie.img.gz

  # Download Retropie
  wget "https://github.com/RetroPie/RetroPie-Setup/releases/download/$retropie_version/retropie-$raspbian_version-$retropie_version-$rpi_version.img.gz" -O "$image_file"

  # Copy the image
  gunzip --stdout "$image_file" | sudo dd bs=4M of="$device"
}

main() {
  action="$1"
  shift

  "$action" "$@"
}

if [[ $# -ne 2 ]]; then
  usage
fi

main "$@"
