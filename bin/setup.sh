#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/common.sh"

usage() {
  echo "usage: $0 <action> <module> [module_args]"
  exit 1
}

setup_all() {
  local action="$1"

  # Don't automatically call dependent setupmodules since they'll all be called
  # in order
  export SKIP_DEPS=true

  local modules
  if [[ "$action" == 'install'* ]]; then
    # First, install wifi and dependencies
    if grep -q '"wifi"' "$config_dir/settings.json"; then
      setup install wifi
    fi
    setup install deps

    # Then install the remaining modules
    modules=$(setting '.setup[] | select(. != "deps" and . != "wifi")')
  else
    modules=$(setting '.setup | reverse[]')
  fi

  while read setupmodule; do
    setup "$action" "$setupmodule"
  done < <(echo "$modules")
}

setup() {
  local action="$1"
  local setupmodule="$2"

  # Always make sure the locale is accurate in case the console session hasn't
  # been restarted
  . /etc/default/locale

  if [ -z "$3" ] && { [ "$setupmodule" == 'system' ] || [[ "$setupmodule" == system-* ]]; }; then
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

  if [ $# -ge 3 ]; then
    print_heading "Running $action for $setupmodule (${*:3})"
  else
    print_heading "Running $action for $setupmodule"
  fi

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

  echo 'Done!'
}

if [[ $# -lt 1 ]]; then
  usage
fi

main "$@"
