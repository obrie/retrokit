#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

keymap_filepath='/etc/rc_keymaps/retropie.toml'

install() {
  conf_cp "$config_dir/ir/rc_maps.cfg" '/etc/rc_maps.cfg' as_sudo=true
  conf_cp "$config_dir/ir/retropie.toml" "$keymap_filepath" as_sudo=true

  # Load
  sudo ir-keytable -t -w "$keymap_filepath"
}

uninstall() {
  rm "$keymap_filepath"
  restore '/etc/rc_maps.cfg'
}

"${@}"
