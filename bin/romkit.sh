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
  local system_settings_file=$(generate_system_settings_file "$system")
  local args=("${@:3}")

  TMPDIR="$tmp_dir" python3 "$lib_dir/romkit/cli.py" "$command" "$system_settings_file" ${args[@]}
}

if [[ $# -lt 1 ]]; then
  usage
fi

main "$@"
