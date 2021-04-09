#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

install() {
  ini_merge "$config_dir/boot/config.txt" '/boot/config.txt' space_around_delimiters=false as_sudo=true
}

uninstall() {
  restore '/boot/config.txt'
}

"${@}"
