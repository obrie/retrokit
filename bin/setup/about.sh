#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='about'
setup_module_desc='Prints various information about retrokit'

show_retrokit_settings() {
  cat "$settings_file"
}

setup "${@}"
