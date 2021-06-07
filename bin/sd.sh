#!/bin/bash

##############
# SD Card management
##############

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/common.sh"

usage() {
  echo "usage:"
  echo " $0 create <device> (run from laptop)"
  echo " $0 backup <device> <backup_dir> (run from laptop)"
  echo " $0 restore <device> <backup_dir> (run from laptop)"
  echo " $0 sync <from_path> <to_path> (run from laptop/retropie)"
  echo " $0 sync_media <from_path> <to_path> (run from laptop/retropie)"
  exit 1
}

restore() {
  [[ $# -ne 2 ]] && usage
  local device=$1
  local restore_from_path=$2
  gunzip --stdout "$restore_from_path/sd-retropie.img.gz" | sudo dd bs=4M of=$device
}

backup() {
  [[ $# -ne 2 ]] && usage
  local device=$1
  local backup_to_path=$2
  mkdir -p "$backup_to_path"

  sudo dd bs=4M if=$device | gzip > "$backup_to_path/sd-retropie.img.gz"
}

sync() {
  [[ $# -ne 2 ]] && usage
  local sync_from_path=$1
  local sync_to_path=$2

  # This should be the full list of paths that might be modified by using
  # the arcade or using retrokit
  local paths=(/opt/retropie/ /etc/ /home/pi/)

  for path in "${paths[@]}"; do
    sudo rsync -av "$sync_from_path$path" "$sync_to_path$path" --delete
  done
}

sync_media() {
  [[ $# -ne 2 ]] && usage
  local sync_from_path=$1
  local sync_to_path=$2

  # This should be the full list of media paths
  local paths=(
    /home/pi/RetroPie/BIOS/fbneo/samples/
    /home/pi/RetroPie/BIOS/mame/samples/
    /home/pi/RetroPie/BIOS/mame2003-plus/samples/
    /home/pi/RetroPie/BIOS/mame2003/samples/
    /home/pi/RetroPie/BIOS/mame2010/samples/
    /home/pi/RetroPie/BIOS/mame2016/samples/
    /home/pi/RetroPie/roms/
    /opt/retropie/configs/all/emulationstation/downloaded_media/
    /opt/retropie/configs/all/retroarch/overlay/
    /opt/retropie/configs/all/skyscraper/cache/
  )

  local remote_user=$(stat -c '%U' "$sync_to_path/home/pi")
  local remote_group=$(stat -c '%G' "$sync_to_path/home/pi")

  for path in "${paths[@]}"; do
    if [ -d "$sync_from_path$path" ]; then
      sudo install -dv -m 0755 -o "$remote_user" -g "$remote_group" "$sync_to_path$path"
      sudo rsync -av "$sync_from_path$path" "$sync_to_path$path" --delete
    fi
  done
}

create() {
  [[ $# -ne 1 ]] && usage
  local device=$1
  local retropie_version=4.7.1
  local raspbian_version=buster
  local rpi_version=rpi4_400
  local image_file="$tmp_dir/retropie-$retropie_version-$raspbian_version-$rpi_version.img.gz"

  # Download Retropie
  download "https://github.com/RetroPie/RetroPie-Setup/releases/download/$retropie_version/retropie-$raspbian_version-$retropie_version-$rpi_version.img.gz" "$image_file"

  # Make sure the device is unmounted
  if df | grep -q "$device"; then
    sudo umount -v ${device}* || true
  fi

  # Copy the image
  echo "Copying image to $device..."
  gunzip -v --stdout "$image_file" | sudo dd bs=4M of="$device"
  local retropie_device=$(lsblk -nl -o PATH,MAJ:MIN "$device" | grep ':2' | cut -d ' ' -f 1)
  if [ -z "$retropie_device" ]; then
    echo 'Could not find retropie partition in lsblk'
    return 1
  fi

  # Expand main partition to consume the entire disk
  echo "Expanding $device to 100% capacity"
  sudo parted -s "$device" resizepart 2 100%
  sudo e2fsck -fv "$retropie_device"
  sudo resize2fs "$retropie_device"

  # Mount the device
  local mount_path="$HOME/retrokit-sdcard"
  mkdir -p "$mount_path"
  sudo mount -v "$retropie_device" "$mount_path"

  # Copy retrokit
  echo "Copying retrokit to /home/pi/retrokit on $retropie_device"
  local remote_user=$(stat -c '%U' "$mount_path/home/pi")
  local remote_group=$(stat -c '%G' "$sync_to_path/home/pi")
  sudo rsync -av --chown "$remote_user:$remote_group" --exclude 'tmp/' "$app_dir/" "$mount_path/home/pi/retrokit/"
  mkdir -v "$mount_path/home/pi/retrokit/tmp"
  touch "$mount_path/home/pi/retrokit/tmp/.gitkeep"
  chown -Rv "$remote_user:$remote_group" "$mount_path/home/pi/retrokit/tmp"

  # Unmount the device
  while ! sudo umount -v "$retropie_device"; do
    sleep 5
  done
  rmdir -v "$mount_path"
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
