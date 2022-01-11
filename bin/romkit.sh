#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/common.sh"

usage() {
  echo "usage:"
  echo " $0 <list|install|organize|vacuum> [system|all] [options]"
  exit 1
}

run() {
  local command=$1
  local system=$2
  local common_settings_file="$app_dir/config/systems/settings-common.json"
  local system_settings_file="$app_dir/config/systems/$system/settings.json"
  local args=("${@:3}")

  if [ -z "$args" ]; then
    args=(--log-level ERROR)
  fi

  TMPDIR="$tmp_dir" python3 "$bin_dir/romkit/cli.py" "$command" <(jq -s '.[0] * .[1]' "$common_settings_file" "$system_settings_file") ${args[@]}
}

main() {
  local command=$1
  local system=$2

  if [ -z "$system" ] || [ "$system" == 'all' ]; then
    while read system; do
      run "$command" "$system" "${@:3}"
    done < <(setting '.systems[] | select(. != "ports")')
  else
    run "$command" "$system" "${@:3}"
  fi
}

if [[ $# -lt 1 ]]; then
  usage
fi

main "$@"
