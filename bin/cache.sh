#!/bin/bash

##############
# Cache management
##############

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/common.sh"

usage() {
  echo "usage:"
  echo " $0 delete|build_emulator_binaries|sync_emulator_binaries"
  exit 1
}

main() {
  local action=$1

  if [[ "$action" == *system* ]]; then
    # Action is system-specific.  Either run against all systems
    # or against a specific system.
    local system=$2

    if [ -z "$system" ] || [ "$system" == 'all' ]; then
      while read system; do
        print_heading "Running $action for $system (${*:3})"
        "$action" "$system" "${@:3}"
      done < <(setting '.systems[]')
    else
      print_heading "Running $action for $system (${*:3})"
      "$action" "$system" "${@:3}"
    fi
  else
    # Action is not system-specific.
    "$action" "${@:2}"
  fi
}

delete() {
  local system=$1

  local delete_dir=$tmp_dir
  if [ -n "$system" ] && [ "$system" != 'all' ]; then
    delete_dir="$delete_dir/$system"
  fi

  # Remove cached data
  rm -rfv "$delete_dir"/*
}

default_binary_packages=(actionmax advmame-joy lr-mame0222 lr-mame0244 lr-mame2016-lightgun lr-swanstation lr-yabasanshiro supermodel3 mame-tools)

# Build binaries for emulators that are added by retrokit
# 
# This must be run on a Raspberry Pi 4 device.  Compilation fails
# pretty hard for a number of the above packages when run on Ubuntu.
build_emulator_binaries() {
  local package=$1
  local dist=$default_retropie_dist
  local platform=$default_retropie_platform
  if [ $# -gt 1 ]; then local "${@:2}"; fi

  if [[ "$(id -u)" -ne 0 ]]; then
    # We must run as sudo since the build  process can take a long time
    echo "Script must be run under sudo. Try 'sudo $0'"
    exit 1
  fi

  local packages
  if [ -z "$package" ] || [ "$package" == 'all' ]; then
    packages=("${default_binary_packages[@]}")
  else
    packages=("$package")
  fi

  # Ensure tmp directories are set up
  if [ ! -d "$retropie_setup_dir/tmp" ]; then
    mkdir -p "$retropie_setup_dir/tmp/archives"
  fi

  export __nameserver=8.8.8.8
  export __builder_dists=$dist
  export __builder_platforms=$platform
  export __builder_makeflags='-j2'

  # Create initial image
  local chroot_dir="$retropie_setup_dir/tmp/build/builder/$dist"
  local chroot_retropie_setup_dir="$chroot_dir/home/pi/RetroPie-Setup"
  if [ ! -d "$chroot_retropie_setup_dir" ]; then
    # Generate a signing key
    export GNUPGHOME="$tmp_ephemeral_dir"
    local gpg_signing_key=retropieproject@gmail.com
    gpg --quick-gen-key --batch --passphrase "" "$gpg_signing_key" 2>/dev/null

    # Build the image
    GNUPGHOME="$tmp_ephemeral_dir" __gpg_signing_key="$gpg_signing_key" "$retropie_setup_dir/retropie_packages.sh" builder chroot_build module

    # Pull the public retropie key
    "$retropie_setup_dir/retropie_packages.sh" image chroot "$chroot_dir" sudo gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys DC9D77FF8208FFC51D8F50CCF1B030906A3B0D31
  fi

  # Copy modules over to the mounted RetroPie-Setup
  local chroot_scriptmodules_dir="$chroot_retropie_setup_dir/ext/retrokit/scriptmodules"
  mkdir -p "$chroot_scriptmodules_dir"
  cp -Rv "$ext_dir/scriptmodules/"* "$chroot_scriptmodules_dir/"

  # Build packages
  mkdir -p "$retropie_setup_dir/tmp/archives"
  "$retropie_setup_dir/retropie_packages.sh" builder chroot_build module "${packages[@]}"
}

# Upload emulator binaries to github
sync_emulator_binaries() {
  local package=$1
  local dist=$default_retropie_dist
  local platform=$default_retropie_platform
  if [ $# -gt 1 ]; then local "${@:2}"; fi

  local packages
  if [ -z "$package" ] || [ "$package" == 'all' ]; then
    packages=("${default_binary_packages[@]}")
  else
    packages=("$package")
  fi

  local release_json=$(curl -sH "Authorization: token $GITHUB_API_KEY" "https://api.github.com/repos/obrie/retrokit/releases/tags/latest")
  local upload_url=$(echo "$release_json" | jq -r '.upload_url' | cut -d'{' -f1)

  for package in "${packages[@]}"; do
    local package_type=$(get_retropie_package_type "$package")

    # Stage the archive file
    local archive_dir="$retropie_setup_dir/tmp/archives/$dist/$platform/kms"
    local archive_file="$archive_dir/$package_type/$package.tar.gz"

    # Upload to github
    if [ -f "$archive_file" ]; then
      local asset_name="$package-$dist-$platform-kms.tar.gz"

      # Get ID of the asset based on given filename.
      local asset_id=$(echo "$release_json" | jq -r ".assets[] | select(.name == \"$asset_name\").id")
      if [ -n "$asset_id" ]; then
        echo "Deleting $asset_name ($asset_id) from release"
        curl -X DELETE -H "Authorization: token $GITHUB_API_KEY" "https://api.github.com/repos/obrie/retrokit/releases/assets/$asset_id"
      fi

      echo "Uploading $asset_name"
      curl -X POST \
        -H "Authorization: token $GITHUB_API_KEY" \
        -H "Accept: application/vnd.github.v3+json" \
        -H "Content-Type: application/gzip" \
        -H "Content-Length: $(wc -c <$archive_file | xargs)" \
        -T "$archive_file" \
        "$upload_url?name=$asset_name"

      echo
    fi
  done
}

if [[ $# -lt 1 ]]; then
  usage
fi

main "$@"
