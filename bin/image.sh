#!/bin/bash

##############
# Image management
##############

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/common.sh"

images_dir="$tmp_dir/images"

# Default image configuration
dist=buster
platform=rpi4_400
retropie_version=4.8
profiles=image-base

create() {
  __parse_args "${@}"

  init

  for action in init_system 'update system' 'update retropie' 'setup install' cleanup_roms cleanup_configs cleanup_tmp; do
    chroot_run "$action"
  done

  export_img
  fix_img
}

init() {
  __require_sudo
  __parse_args "${@}"

  local image_filename="$(__image_name).img"
  local image_file="$images_dir/$image_filename"

  # Download image
  if [ ! -f "$image_file" ]; then
    local url="https://github.com/RetroPie/RetroPie-Setup/releases/download/$retropie_version/$image_filename.gz"
    local compressed_image_file="$images_dir/$image_filename.gz"
    download "$url" "$compressed_image_file"
    gunzip -v --stdout "$compressed_image_file" | dd bs=4M of="$image_file" status=progress
  fi

  # Install dependencies
  "$retropie_setup_dir/retropie_packages.sh" image depends

  local chroot_dir=$(__chroot_dir)
  if [ ! -d "$chroot_dir" ]; then
    # Mount image
    local partitions=($(kpartx -s -a -v "$image_file" | awk '{ print "/dev/mapper/"$3 }'))
    local part_boot=${partitions[0]}
    local part_root=${partitions[1]}

    local tmp_mount_dir=$(mktemp -d -p "$tmp_ephemeral_dir")
    mkdir -p "$tmp_mount_dir/boot"

    mount "$part_root" "$tmp_mount_dir"
    mount "$part_boot" "$tmp_mount_dir/boot"

    echo "Creating chroot from $image_file ..."

    mkdir -p "$chroot_dir"
    rsync -aAHX --numeric-ids --delete "$tmp_mount_dir/" "$chroot_dir/"

    umount -l "$tmp_mount_dir/boot" "$tmp_mount_dir"
    rm -rf "$tmp_mount_dir"

    kpartx -d "$image_file"
  fi
}

# Create image
export_img() {
  __parse_args "${@}"

  local chroot_dir=$(__chroot_dir)

  local image_name="retrokit-$dist-$retrokit_version-$platform"
  local image_file="$images_dir/$image_name.img"

  echo "Creating image $image_name ..."

  mkdir -p "$retropie_setup_dir/tmp/build/image"
  rm -fv "$image_file"
  "$retropie_setup_dir/retropie_packages.sh" image create "$image_file" "$chroot_dir"
}

# Fixes the kernel configuration to reflect PARTUUID changes made by retropie
fix_img() {
  __require_sudo
  __parse_args "${@}"

  local image_name="retrokit-$dist-$retrokit_version-$platform"
  local image_file="$images_dir/$image_name.img"

  # Mount
  local boot_partition=$(kpartx -s -a -v "$image_file" | awk '{ print "/dev/mapper/"$3 }' | head -n1)
  local boot_dir=$(mktemp -d -p "$tmp_dir")
  mount "$boot_partition" "$boot_dir"

  # Remove cmdline.txt backup since the PARTUUID is no longer accurate (and includes init commands)
  rm -fv "$boot_dir/cmdline.txt.rk-src"

  # Unmount
  umount -l "$boot_dir"
  kpartx -d "$image_file"
}

# Compress image
compress_img() {
  __parse_args "${@}"

  local chroot_dir=$(__chroot_dir)

  local image_name="retrokit-$dist-$retrokit_version-$platform"
  local image_file="$images_dir/$image_name.img"

  echo "Compressing image $image_name ..."

  rm -fv "$image_file.gz"
  gzip -c "$image_file" > "$image_file.gz"
}

chroot_run() {
  __require_sudo

  local args=$1
  __parse_args "${@:2}"

  local chroot_dir=$(__chroot_dir)
  local setup_script_path='/home/pi/install_retrokit.sh'
  local setup_script_chroot_path="$chroot_dir/$setup_script_path"

  cat > "$setup_script_chroot_path" <<_EOF_
#!/bin/bash
set -e

cd

[ -d retrokit ] || git clone https://github.com/obrie/retrokit.git
cd retrokit

# Run retrokit
PROFILES=$profiles \
  SCREENSCRAPER_USERNAME=$SCREENSCRAPER_USERNAME \
  SCREENSCRAPER_PASSWORD=$SCREENSCRAPER_PASSWORD \
  IA_USERNAME=$IA_USERNAME \
  IA_PASSWORD=$IA_PASSWORD \
  RETROKIT_HAS_EXPORTS=\
  bin/image.sh run_$args
_EOF_

  # Run script
  export __nameserver=8.8.8.8
  "$retropie_setup_dir/retropie_packages.sh" image chroot "$chroot_dir" bash "$setup_script_path"

  # Clean up
  rm "$setup_script_chroot_path"
}

__image_name() {
  echo "retropie-$dist-$retropie_version-$platform"
}

__chroot_dir() {
  echo "$images_dir/$(__image_name)"
}

# Parses command-line arguments with simple param=value
__parse_args() {
  local dist=$dist
  local platform=$platform
  local retropie_version=$retropie_version
  local profiles=$profiles
  if [ $# -gt 0 ]; then local "${@}"; fi

  declare -g dist=$dist platform=$platform retropie_version=$retropie_version profiles=$profiles
}

# Initializes various files / directories on the system
run_init_system() {
  sudo chmod 1777 /dev/shm
  echo "export PROFILES=\${PROFILES:-filter-local,lightgun}" > .env
}

# Update components of the system
run_update() {
  __reset_env

  "$bin_dir/update.sh" ${@}
}

# Run the given setup module
run_setup() {
  __reset_base_env

  "$bin_dir/setup.sh" ${@}
}

# Run an interactive console
run_bash() {
  __reset_base_env

  bash
}

# Remove stubbed-out roms
run_cleanup_roms() {
  __reset_env

  PROFILES=filter-none "$bin_dir/vacuum.sh" roms | bash
  PROFILES=filter-none "$bin_dir/setup.sh" install system-roms-download
}

# Re-run setup to bring back the expected defaults
run_cleanup_configs() {
  __reset_env

  "$bin_dir/setup.sh" install scraper
  "$bin_dir/setup.sh" restore auth-internetarchive
}

# Clear all temporary files
run_cleanup_tmp() {
  if [ -f "$home_dir/.bash_history" ]; then
    truncate -s0 "$home_dir/.bash_history"
  fi

  rm -rf "$tmp_dir"/*
}

__reset_base_env() {
  unset LOGIN_USER
  unset LOGIN_PASSWORD
  unset VNC_PASSWORD
  unset RETROARCH_PASSWORD
}

__reset_service_env() {
  unset SCREENSCRAPER_USERNAME
  unset SCREENSCRAPER_PASSWORD
  unset IA_USERNAME
  unset IA_PASSWORD
}

__reset_env() {
  __reset_base_env
  __reset_service_env
}

__require_sudo() {
  if [[ "$(id -u)" -ne 0 ]]; then
    echo "Script must be run under sudo. Try 'sudo $0'"
    exit 1
  fi
}

"$@"
