#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

export PROFILES=metakit
. "$dir/common.sh"

usage() {
  echo "usage:"
  echo " $0 <cache_external_data|format|vacuum|recache_external_data|rescrape|scrape_incomplete|scrape_new|scrape_missing|update|update_dats|update_groups|update_metadata|validate|validate_discovery> [system|all] [options]"
  exit 1
}

main() {
  local command=$1
  local system=$2

  if [ -z "$system" ] || [ "$system" == 'all' ]; then
    while read system; do
      print_heading "Running $command for $system (${*:3})"
      run "$command" "$system" "${@:3}"
    done < <(setting '.systems[]')
  else
    run "$command" "$system" "${@:3}"
  fi
}

run() {
  local command=$1
  local system=$2
  local system_settings_file=$(generate_system_settings_file "$system" false)

  local args=("${@:3}")
  if [ -z "$args" ]; then
    args=(--log-level INFO)
  fi

  local is_shared=$(jq -r '.metadata .shared' "$system_settings_file")
  if [ "$is_shared" != 'true' ]; then
    TMPDIR="$tmp_dir" python3 "$lib_dir/metakit/cli.py" "$command" "$system_settings_file" ${args[@]}
  else
    >&2 echo "$system uses shared data file"
  fi
}

if [[ $# -lt 1 ]]; then
  usage
fi

main "$@"
