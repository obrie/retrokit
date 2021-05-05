#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

# Global configuration overrides
install_config() {
  if [ -f "$system_config_dir/retroarch.cfg" ]; then
    ini_merge "$system_config_dir/retroarch.cfg" "$retropie_system_config_dir/retroarch.cfg"
  fi
}

# Global core options
install_core_options() {
  if [ -f "$system_config_dir/retroarch-core-options.cfg" ]; then
    # Don't restore since it'll be written to by multiple systems
    ini_merge "$system_config_dir/retroarch-core-options.cfg" '/opt/retropie/configs/all/retroarch-core-options.cfg' restore=false
  fi
}

install() {
  install_config
  install_core_options
}

uninstall() {
  restore "$retropie_system_config_dir/retroarch.cfg"
}

"$1" "${@:3}"
