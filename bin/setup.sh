#!/bin/bash

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
      run "$setupmodule" "$action" "$system"
    done < <(setting '.systems[]')
  else
    # Setting up an individual module
    run "$setupmodule" "$action" "${@:3}"
  fi
}

run() {
  local setupmodule=$1
  local action=$2

  print_heading "Running $action for $setupmodule (${@:3})"
  "$dir/setup/$setupmodule.sh" "$action" "${@:3}"
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
