#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../common.sh"

configscripts_dir="/opt/retropie/supplementary/emulationstation/scripts/configscripts"

install() {
  # Add autoconfig scripts
  while read configscript_path; do
    cp "$configscript_path" "$configscripts_dir/"
  done < <(find "$bin_dir/controllers" -name '*.sh')

  # Run RetroPie autoconfig for each controller input
  while read input_path; do
    cp "$input_path" "$HOME/.emulationstation/es_temporaryinput.cfg"
    /opt/retropie/supplementary/emulationstation/scripts/inputconfiguration.sh
  done < <(find "$config_dir/controllers/inputs" -name '*.cfg')
}

uninstall() {
  # Reset inputs
  sudo "$HOME/RetroPie-Setup/retropie_packages.sh" emulationstation init_input

  # Remove autoconfig scripts
  while read configscript_path; do
    local configscript_name=$(basename "$configscript_path")
    rm -f "$configscripts_dir/$configscript_name"
  done < <(find "$bin_dir/controllers" -name '*.sh')
}

"${@}"
