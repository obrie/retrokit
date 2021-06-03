#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/common.sh"

system="$1"
system_settings_file="$app_dir/config/systems/$system/settings.json"

romkit_cli() {
  TMPDIR="$tmp_dir" python3 "$bin_dir/romkit/cli.py" $1 "$system_settings_file" ${@:2}
}

list() {
  romkit_cli list ${@}
}

vacuum() {
  romkit_cli vacuum ${@}
}

organize() {
  romkit_cli organize ${@}
}

if [[ $# -gt 2 ]]; then
  "$2" "${@:3}"
else
  "$2" --log-level ERROR
fi
