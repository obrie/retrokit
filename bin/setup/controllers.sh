#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

install() {
  # Run RetroPie autoconfig for each controller input
  while read input_path; do
    cp "$input_path" "$HOME/.emulationstation/es_temporaryinput.cfg"
    /opt/retropie/supplementary/emulationstation/scripts/inputconfiguration.sh
  done < <(find "$config_dir/controllers/inputs" -name '*.cfg')
}

uninstall() {
  restore "$HOME/.emulationstation/es_input.cfg"
}

"${@}"
