#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

# Implementation sourced from RetroPie-Setup
install() {
  local kernel="$(uname -r)"

  while read module_path; do
    local module_name=$(basename "$module_path")
    local version=1.0

    # Remove any existing patch set
    if dkms status | grep -q "^$module_name"; then
      remove "$module_name"
    fi

    # Symlink the path
    ln -sf "$module_path" "/usr/src/${module_name}-$version"

    # Install the module
    dkms install --no-initrd --force -m "$module_name" -v "$version" -k "$kernel"
    if ! dkms status "$module_name/$version" -k "$kernel" | grep -q installed; then
      # Force building for any kernel that has source/headers
      local k_ver
      while read k_ver; do
        if [[ -d "$(realpath /lib/modules/$k_ver/build)" ]]; then
          dkms install --no-initrd --force -m "$module_name/$version" -k "$k_ver"
        fi
      done < <(ls -r1 /lib/modules)
    fi

    if ! dkms status "$module_name/$version" | grep -q installed; then
      md_ret_errors+=("Failed to install $md_id")
      return 1
    fi
  done < <(find "$config_dir/dkms" -mindepth 1 -maxdepth 1 -type d)
}

remove() {
  local module_name=$1

  for ver in $(dkms status "$module_name" | cut -d',' -f2 | cut -d':' -f1); do
    dkms remove -m "$module_name" -v "$ver" --all
    rm -f "/usr/src/${module_name}-${ver}"
  done

  if [[ -n "$(lsmod | grep ${module_name/-/_})" ]]; then
    rmmod "$module_name"
  fi
}

uninstall() {
}

"${@}"
