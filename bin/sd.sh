#!/bin/bash

##############
# SD Card management
##############

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/common.sh"

usage() {
  echo "usage:"
  echo " $0 create <device> (run from laptop)"
  echo " $0 backup <device> <backup_file.tar.gz> (run from laptop)"
  echo " $0 restore <device> <backup_file.tar.gz> (run from laptop)"
  echo " $0 sync_full <from_dir> <to_dir> (run from laptop/retropie)"
  echo " $0 sync_media <from_dir> <to_dir> (run from laptop/retropie)"
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
  local backup_file=$2
  gunzip --stdout "$backup_file" | sudo dd bs=4M of=$device status=progress
}

backup() {
  [[ $# -ne 2 ]] && usage
  local device=$1
  local backup_file=$2
  mkdir -p "$(dirname "$backup_file")"

  sudo dd bs=4M if=$device status=progress | gzip > "$backup_file"
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

sync_full() {
  [[ $# -lt 2 ]] && usage
  local sync_from_dir=${1%/}
  local sync_to_dir=${2%/}
  local dry_run=false
  if [ $# -gt 2 ]; then local "${@:3}"; fi

  local rsync_opts=''
  if [ "$dry_run" == 'true' ]; then
    rsync_opts="$rsync_opts --dry-run"
  fi

  # -a (Archive)
  # -v (Verbose)
  # -x (Stay on one filesystem, i.e. only copy from one filesystem)
  # -H (Preserve hard links)
  # -A (Preserve ACLs / permissions)
  # -W (Avoid calculating deltas / diffs)
  # -X (Preserve extended attributes)
  # -S (Handle sparse files efficiently)
  # --numeric-ids (Avoid mapping uid/guid values by user/group name)
  sudo rsync -avxHAWXS --numeric-ids --delete $rsync_opts "$sync_from_dir/" "$sync_to_dir/"
}

sync_media() {
  [[ $# -lt 2 ]] && usage
  local sync_from_dir=${1%/}
  local sync_to_dir=${2%/}
  local dry_run=false
  local delete=false
  if [ $# -gt 2 ]; then local "${@:3}"; fi

  if [[ "$(id -u)" -ne 0 ]]; then
    # We must run as sudo since the rsync can take a long time
    echo "Script must be run under sudo. Try 'sudo $0'"
    exit 1
  fi

  local rsync_opts=''
  if [ "$dry_run" == 'true' ]; then
    rsync_opts="$rsync_opts --dry-run"
  fi

  if [ "$delete" == 'true' ]; then
    rsync_opts="$rsync_opts --delete"
  fi

  # This should be the full list of media paths
  local paths=(
    /home/pi/RetroPie/BIOS/
    /home/pi/RetroPie/roms/
    "$retropie_configs_dir/all/emulationstation/downloaded_media/"
    "$retropie_configs_dir/all/emulationstation/gamelists/"
    "$retropie_configs_dir/all/retroarch/overlay/"
    "$retropie_configs_dir/all/skyscraper/cache/"
  )

  for path in "${paths[@]}"; do
    if [ -d "$sync_from_dir$path" ]; then
      # Get the top-level new directory we're creating
      local sync_to_base_path="$sync_to_dir$path"
      while [ ! -d "$(dirname "$sync_to_base_path")" ]; do
        sync_to_base_path=$(dirname "$sync_to_base_path")
      done

      # Make sure permissions are set properly
      if [ ! -d "$sync_to_base_path" ]; then
        local remote_user=$(stat -c '%U' "$sync_from_dir$path")
        local remote_group=$(stat -c '%G' "$sync_from_dir$path")
        mkdir -pv "$sync_to_dir$path"
        chown -Rv "$remote_user:$remote_group" "$sync_to_base_path"
      fi

      # Copy over files
      sudo rsync -av $rsync_opts "$sync_from_dir$path" "$sync_to_dir$path"
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

  local images_dir="$tmp_dir/images"
  mkdir -p "$images_dir"
  local image_name="retropie-$raspbian_version-$retropie_version-$rpi_version"
  local image_file="$images_dir/$image_name.img.gz"

  # Download Retropie
  download "https://github.com/RetroPie/RetroPie-Setup/releases/download/$retropie_version/$image_name.img.gz" "$image_file"

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
  # available disk space causes the image to go into a failure
  # boot loop.  This is why we expand to *almost* 100% :/
  # 
  # I tried changing the disk id, but this didn't make a difference.
  echo "Expanding $device to 100% capacity"
  local device_size=$(cat "/sys/block/$device_id/size")
  sudo parted -s "$device" u s resizepart 2 $((device_size-2))
  sudo e2fsck -fv "$retropie_device"
  sudo resize2fs -p "$retropie_device"

  # Claim back some of the disk from system reserved space (default is 5%)
  sudo tune2fs -m 2 "$retropie_device"

  # Mount the device
  local mount_dir="$home/retrokit-sdcard"
  mkdir -p "$mount_dir"
  sudo mount -v "$retropie_device" "$mount_dir"

  # Modify partition timeout to account for fsck runtime
  sudo sed -i '2,$s/defaults/defaults,x-systemd.device-timeout=3600s/g' "$mount_dir/etc/fstab"

  # Copy retrokit
  echo "Copying retrokit to /home/pi/retrokit on $retropie_device"
  local remote_user=$(stat -c '%U' "$mount_dir/home/pi")
  local remote_group=$(stat -c '%G' "$sync_to_dir/home/pi")
  sudo rsync -a --chown "$remote_user:$remote_group" --exclude 'tmp/' --exclude '__pycache__/' "$app_dir/" "$mount_dir/home/pi/retrokit/"
  mkdir -v "$mount_dir/home/pi/retrokit/tmp"
  touch "$mount_dir/home/pi/retrokit/tmp/.gitkeep"
  chown -Rv "$remote_user:$remote_group" "$mount_dir/home/pi/retrokit/tmp"

  # Unmount the device
  echo "Unmounting $retropie_device..."
  while ! sudo umount -v "$retropie_device"; do
    sleep 5
  done
  rmdir -v "$mount_dir"

  echo "Done!"
}

if [[ $# -lt 1 ]]; then
  usage
fi

main "$@"
