#!/bin/bash

##############
# SD Card management
##############

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/common.sh"

usage() {
  echo "usage:"
  echo " $0 create <device> (run from laptop)"
  echo " $0 backup <device> <backup_path.tar.gz> (run from laptop)"
  echo " $0 restore <device> <backup_path.tar.gz> (run from laptop)"
  echo " $0 sync <from_path> <to_path> (run from laptop/retropie)"
  echo " $0 sync_media <from_path> <to_path> (run from laptop/retropie)"
  exit 1
}

main() {
  local action="$1"
  shift

  "$action" "$@"
}

restore() {
  [[ $# -ne 2 ]] && usage
  local device=$1
  local restore_from_path=${2%/}
  gunzip --stdout "$restore_from_path" | sudo dd bs=4M of=$device status=progress
}

backup() {
  [[ $# -ne 2 ]] && usage
  local device=$1
  local backup_to_path=${2%/}
  mkdir -p "$(dirname "$backup_to_path")"

  sudo dd bs=4M if=$device status=progress | gzip > "$backup_to_path"
}

clone() {
  [[ $# -ne 2 ]] && usage
  local source_device=$1
  local target_device=$2

  read -p "This will overwrite the data on $target_device. Are you sure (y/n)? " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo dd bs=4M if=$source_device of=$target_device status=progress
  fi
}

sync() {
  [[ $# -ne 2 ]] && usage
  local sync_from_path=${1%/}
  local sync_to_path=${2%/}

  # This should be the full list of paths that might be modified by using
  # the arcade or using retrokit
  local paths=(/opt/retropie/ /etc/ /home/pi/)

  for path in "${paths[@]}"; do
    sudo rsync -av "$sync_from_path/$path" "$sync_to_path/$path" --delete
  done
}

sync_media() {
  [[ $# -ne 2 ]] && usage
  local sync_from_path=${1%/}
  local sync_to_path=${2%/}
  local delete=false
  if [ $# -gt 2 ]; then local "${@:3}"; fi

  local rsync_args=''
  if [ "$delete" == 'true' ]; then
    rsync_args='--delete'
  fi

  # This should be the full list of media paths
  # TODO: Double check ownership is set correctly in all parent folders
  local paths=(
    /home/pi/RetroPie/BIOS/fbneo/samples/
    /home/pi/RetroPie/BIOS/mame/samples/
    /home/pi/RetroPie/BIOS/mame2003-plus/samples/
    /home/pi/RetroPie/BIOS/mame2003/samples/
    /home/pi/RetroPie/BIOS/mame2010/samples/
    /home/pi/RetroPie/BIOS/mame2016/samples/
    /home/pi/RetroPie/roms/
    /opt/retropie/configs/all/emulationstation/downloaded_media/
    /opt/retropie/configs/all/emulationstation/gamelists/
    /opt/retropie/configs/all/retroarch/overlay/
    /opt/retropie/configs/all/skyscraper/cache/
  )

  for path in "${paths[@]}"; do
    if [ -d "$sync_from_path$path" ]; then
      # Get the top-level new directory we're creating
      local sync_to_base_path="$sync_to_path$path"
      while [ ! -d "$(dirname "$sync_to_base_path")" ]; do
        sync_to_base_path=$(dirname "$sync_to_base_path")
      done

      # Make sure permissions are set properly
      if [ ! -d "$sync_to_base_path" ]; then
        local remote_user=$(stat -c '%U' "$sync_from_path$path")
        local remote_group=$(stat -c '%G' "$sync_from_path$path")
        mkdir -pv "$sync_to_path$path"
        chown -Rv "$remote_user:$remote_group" "$sync_to_base_path"
      fi

      # Copy over files
      sudo rsync -av $rsync_args "$sync_from_path$path" "$sync_to_path$path"
    fi
  done
}

create() {
  [[ $# -ne 1 ]] && usage
  local device=$1
  local device_id=$(basename "$device")

  local retropie_version=4.8
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
  sudo wipefs -a "$device"
  gunzip -v --stdout "$image_file" | sudo dd bs=4M of="$device" status=progress
  local retropie_device=$(lsblk -nl -o PATH,TYPE -x PATH "$device" | grep part | cut -d ' ' -f 1 | head -2 | tail -1)
  if [ -z "$retropie_device" ]; then
    echo 'Could not find retropie partition in lsblk'
    return 1
  fi

  # Expand main partition to consume the entire disk
  # *NOTE* For reasons I don't yet understand, resizing to 100% of the
  # available disk space causes the image to go into an failure
  # boot loop.  This is why we expand to *almost* 100% :/
  # 
  # I tried changing the disk id, but this didn't make a difference.
  echo "Expanding $device to 100% capacity"
  local device_size=$(cat "/sys/block/$device_id/size")
  sudo parted -s "$device" u s resizepart 2 $((device_size-2))
  sudo e2fsck -fv "$retropie_device"
  sudo resize2fs -p "$retropie_device"

  # Mount the device
  local mount_path="$HOME/retrokit-sdcard"
  mkdir -p "$mount_path"
  sudo mount -v "$retropie_device" "$mount_path"

  # Modify partition timeout to account for fsck runtime
  sudo sed -i '2,$s/defaults/defaults,x-systemd.device-timeout=900s/g' "$mount_path/etc/fstab"

  # Copy retrokit
  echo "Copying retrokit to /home/pi/retrokit on $retropie_device"
  local remote_user=$(stat -c '%U' "$mount_path/home/pi")
  local remote_group=$(stat -c '%G' "$sync_to_path/home/pi")
  sudo rsync -av --chown "$remote_user:$remote_group" --exclude 'tmp/' --exclude '__pycache__/' "$app_dir/" "$mount_path/home/pi/retrokit/"
  mkdir -v "$mount_path/home/pi/retrokit/tmp"
  touch "$mount_path/home/pi/retrokit/tmp/.gitkeep"
  chown -Rv "$remote_user:$remote_group" "$mount_path/home/pi/retrokit/tmp"

  # Unmount the device
  while ! sudo umount -v "$retropie_device"; do
    sleep 5
  done
  rmdir -v "$mount_path"
}

if [[ $# -lt 1 ]]; then
  usage
fi

main "$@"
