#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

install() {
  # EmulationStation input config
  file_cp "$config_dir/controllers/es_input.cfg" "$HOME/.emulationstation/es_input.cfg"

  # Autoconfig files for Retroarch
  while read autoconfig_path; do
    local autoconfig_filename=$(basename "$autoconfig_path")
    file_cp "$autoconfig_path" "/opt/retropie/configs/all/retroarch/autoconfig/$autoconfig_filename"
  done < <(find "$config_dir/controllers/autoconfig" -type f)
}

uninstall() {
  while read autoconfig_path; do
    local autoconfig_filename=$(basename "$autoconfig_path")
    restore "/opt/retropie/configs/all/retroarch/autoconfig/$autoconfig_filename"
  done < <(find "$config_dir/controllers/autoconfig" -type f)

  restore "$HOME/.emulationstation/es_input.cfg"
}

"${@}"
