#!/bin/bash

##############
# SD Card management
##############

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/common.sh"

usage() {
  echo "usage:"
  echo " $0 create <device> (run from laptop)"
  echo " $0 backup <device> <backup_dir> (run from laptop)"
  echo " $0 restore <device> <backup_dir> (run from laptop)"
  echo " $0 sync <path> (run from retropie)"
  exit 1
}

restore() {
  local device=$1
  local restore_from_path=$2
  gunzip --stdout "$restore_from_path/sd-retropie.img.gz" | sudo dd bs=4M of=$device
}

backup() {
  local device=$1
  local backup_to_path=$2
  sudo dd bs=4M if=$device | gzip > "$backup_to_path/sd-retropie.img.gz"
}

sync() {
  local sync_to_path=$1

  # This should be the full list of paths that might be modified by the using
  # the arcade or using retrokit
  local paths=(/opt/retropie /etc /home/pi)

  for path in "${paths[@]}"; do
    sudo rsync -av "$path" "$sync_to_path/$path" --delete
  done
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

if [[ $# -lt 1 ]]; then
  usage
fi

main "$@"
