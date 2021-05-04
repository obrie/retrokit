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
    setup "$setupmodule" "$actions"
  done < <(setting '.modules.setup[]')

  # Restore globals for files used across multiple modules
  "$dir/setup/system-all.sh" restore_globals

  # Set up systems
  while read system; do
    setup_system "$system"
  done < <(setting '.systems[] | select(. != "retropie")')
}

setup_system() {
  local system="$1"

  while read -r systemmodule; do
    # Ports only get the scrape module
    if [ "$systemmodule" == 'scrape' ] || [ "$system" != 'ports' ]; then
      "$dir/setup/system-$systemmodule.sh" "$action" "$system"
    fi
  done < <(setting '.modules.system[]')

  # System-specific actions
  if [ -f "$dir/setup/systems/$system.sh" ]; then
    "$dir/setup/systems/$system.sh" "$action"
  fi
}

setup() {
  local action="$1"
  local setupmodule="$2"

  if [ "$setupmodule" == "system" ]; then
    # Setting up all modules on an individual system
    setup_system "$3"
  elif [ -z "$3" ] && [[ "$setupmodule" == system-* ]]; then
    # Setting up an individual system module for all systems
    while read system; do
      # Ports only get the scrape module
      if [ "$setupmodule" == 'system-scrape' ] || [ "$system" != 'ports' ]; then
        "$dir/setup/$setupmodule.sh" "$action" "$system"
      fi
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
