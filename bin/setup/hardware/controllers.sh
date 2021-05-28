#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../common.sh"

configscripts_dir='/opt/retropie/supplementary/emulationstation/scripts/configscripts'

install() {
  # Add autoconfig scripts
  while read autoconfig_name; do
    sudo cp "$bin_dir/controllers/$autoconfig_name.sh" "$configscripts_dir/"
  done < <(jq '.hardware.controllers.autoconfig[]')

  # Run RetroPie autoconfig for each controller input
  while read input_name; do
    cp "$config_dir/controllers/inputs/$input_name.cfg" "$HOME/.emulationstation/es_temporaryinput.cfg"
    /opt/retropie/supplementary/emulationstation/scripts/inputconfiguration.sh
  done < <(jq '.hardware.controllers.inputs[]')
}

uninstall() {
  # Reset inputs
  sudo "$HOME/RetroPie-Setup/retropie_packages.sh" emulationstation init_input

  # Remove autoconfig scripts
  while read autoconfig_name; do
    sudo rm -f "$configscripts_dir/$autoconfig_name.sh"
  done < <(jq '.hardware.controllers.autoconfig[]')
}

"${@}"
