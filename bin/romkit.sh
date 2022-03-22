#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/common.sh"

usage() {
  echo "usage:"
  echo " $0 <list|install|organize|vacuum> [system|all] [options]"
  exit 1
}

main() {
  local command=$1
  local system=$2

  if [ -z "$system" ] || [ "$system" == 'all' ]; then
    while read system; do
      run "$command" "$system" "${@:3}"
    done < <(setting '.systems[]')
  else
    run "$command" "$system" "${@:3}"
  fi
}

run() {
  local command=$1
  local system=$2

  # Build settings file
  local system_settings_file="$(mktemp -p "$tmp_ephemeral_dir")"
  echo '{}' > "$system_settings_file"
  json_merge '{config_dir}/systems/settings-common.json' "$system_settings_file" backup=false >/dev/null
  json_merge "{config_dir}/systems/$system/settings.json" "$system_settings_file" backup=false >/dev/null

  local args=("${@:3}")
  if [ -z "$args" ]; then
    args=(--log-level ERROR)
  fi

  TMPDIR="$tmp_dir" python3 "$bin_dir/romkit/cli.py" "$command" "$system_settings_file" ${args[@]}
}

if [[ $# -lt 1 ]]; then
  usage
fi

main "$@"
