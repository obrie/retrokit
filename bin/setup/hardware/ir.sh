#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../common.sh"

keymap_filepath='/etc/rc_keymaps/tivo.toml'

install() {
  sudo apt install -y ir-keytable

  file_cp "$config_dir/ir/rc_maps.cfg" '/etc/rc_maps.cfg' as_sudo=true
  file_cp "$config_dir/ir/retropie.toml" "$keymap_filepath" as_sudo=true
  sudo chmod 644 "$keymap_filepath"

  # Load
  sudo ir-keytable -w "$keymap_filepath"
}

uninstall() {
  rm "$keymap_filepath"
  restore '/etc/rc_maps.cfg'
}

"${@}"
