#!/bin/bash

set -ex

system='dreamcast'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../system-common.sh"

install() {
  if [ -d "$system_config_dir/mappings" ]; then
    while read mapping_file; do
      local mapping_name=$(basename "$mapping_file")
      file_cp "$mapping_file" "/opt/retropie/configs/dreamcast/mappings/$mapping_name"
    done < <(find "$system_config_dir/mappings" -type f)
  fi
}

uninstall() {
  echo 'No restore for dreamcast'
}

"${@}"
