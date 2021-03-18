#!/bin/bash

##############
# SD Card management
##############

set -ex

DIR=$(dirname "$0")
APP_DIR=$(cd "$DIR/.." && pwd)

usage() {
  echo "usage: $0 <create|backup|restore> <boot_device> <core_device>"
  exit 1
}

restore_file() {
  partition=$1
  device=$2

  gunzip --stdout "$APP_DIR/backups/stable/sd-retropie-$partition.iso.gz" | sudo dd bs=4M of=$device
}

restore() {
  boot_device=$1
  core_device=$2

  restore_file boot "$boot_device"
  restore_file core "$core_device"
}

backup_file() {
  partition=$1
  device=$2

  sudo dd bs=4M if=$device | gzip | dd bs=4M of="$APP_DIR/backups/sd-retropie-$partition.iso.gz"
}

backup() {
  boot_device=$1
  core_device=$2

  backup_file boot "$boot_device"
  backup_file core "$core_device"
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

if [[ $# -ne 3 ]]; then
  usage
fi

main "$@"
