#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

setup_module_id='system-roms-download'
setup_module_desc='Download ROMs via romkit'

build() {
  local args=()
  if [ "$DEBUG" == 'true' ]; then
    args+=(--log_level DEBUG)
  fi

  echo 'Looking for new ROMs to download...'
  romkit_cli install ${args[@]}
}

# Outputs the commands required to remove files no longer required by the current
# list of roms installed
vacuum() {
  romkit_cli vacuum
}

setup "${@}"
