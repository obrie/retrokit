#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/common.sh"

system="$1"
system_settings_file="$app_dir/config/systems/$system/settings.json"

romkit_cli() {
  TMPDIR="$tmp_dir" python3 bin/romkit/cli.py $1 "$system_settings_file" ${@:2}
}

list() {
  romkit_cli list --log-level ERROR
}

vacuum() {
  romkit_cli vacuum --log-level ERROR
}

organize() {
  romkit_cli organize --log-level ERROR
}

"$2" "${@:3}"
