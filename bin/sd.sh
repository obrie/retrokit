#!/bin/bash

##############
# SD Card management
##############

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/common.sh"

usage() {
  echo "usage: $0 <create|backup|restore> <device>"
  exit 1
}

restore() {
  local device=$1
  gunzip --stdout "$app_dir/backups/stable/sd-retropie.iso.gz" | sudo dd bs=4M of=$device
}

backup() {
  local device=$1
  sudo dd bs=4M if=$device | gzip | dd bs=4M of="$app_dir/backups/sd-retropie.iso.gz"
}

create() {
  local device=$1
  local retropie_version=4.7.1
  local raspbian_version=buster
  local rpi_version=rpi4_400
  local image_file="/tmp/retropie-$retropie_version-$raspbian_version-$rpi_version.img.gz"

  # Download Retropie
  download "https://github.com/RetroPie/RetroPie-Setup/releases/download/$retropie_version/retropie-$raspbian_version-$retropie_version-$rpi_version.img.gz" "$image_file"

  # Copy the image
  gunzip --stdout "$image_file" | sudo dd bs=4M of="$device"
}

main() {
  local action="$1"
  shift

  "$action" "$@"
}

if [[ $# -ne 2 ]]; then
  usage
fi

main "$@"
