#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/common.sh"

usage() {
  echo "usage: $0 <action> <module> [module_args]"
  exit 1
}

setup_all() {
  local action="$1"

  while read -r setupmodule; do
    setup "$action" "$setupmodule"
  done < <(setting '.modules[]')
}

setup() {
  local action="$1"
  local setupmodule="$2"

  if [ -z "$3" ] && [[ "$setupmodule" == system-* ]]; then
    # Setting up an individual system module for all systems
    while read system; do
      # Ports only get the scrape module
      "$dir/setup/$setupmodule.sh" "$action" "$system"
    done < <(setting '.systems[] | select(. != "retropie")')
  else
    # Setting up an individual module
    "$dir/setup/$setupmodule.sh" "$action" "${@:3}"
  fi
}

main() {
  local action="$1"
  local setupmodule="$2"

  if [ -n "$setupmodule" ]; then
    setup "$action" "$setupmodule" "${@:3}"
  else
    setup_all "$action"
  fi
}

if [[ $# -lt 1 ]]; then
  usage
fi

main "$@"
