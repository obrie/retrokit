#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='retropie-packages'
setup_module_desc='Install a predefined set of packages with no additional configurations'

build() {
  while read package_name; do
    install_retropie_package "$package_name" "${@:2}"
  done < <(__list_packages "$1")
}

remove() {
  while read package_name; do
    uninstall_retropie_package "$package_name"
  done < <(__list_packages "$1")
}

__list_packages() {
  local package_name=$1

  if [ -n "$package_name" ]; then
    echo "$package_name"
  else
    setting '.retropie .packages | select(.) | .[]'
  fi
}

setup "${@}"
