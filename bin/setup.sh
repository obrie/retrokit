#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/common.sh"

usage() {
  echo "usage: $0 <action> <module> [module_args]"
  exit 1
}

setup_all() {
  local action="$1"
  local from_setupmodule=''
  local to_setupmodule=''
  if [ $# -gt 1 ]; then local "${@:2}"; fi

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
    modules=$(list_setupmodules | grep -Ev '^(deps|wifi)')
  elif [[ "$action" =~ ^(uninstall|restore|remove) ]]; then
    modules=$(list_setupmodules | tac)
  else
    modules=$(list_setupmodules)
  fi

  __confirm "$action"

  while read setupmodule; do
    setup "$action" "$setupmodule"
  done < <(echo "$modules" | sed -n "\|${from_setupmodule:-.*}|, \|${to_setupmodule}|p")
}

setup() {
  local action="$1"
  local setupmodule="$2"

  # Always make sure the locale is accurate in case the console session hasn't
  # been restarted
  . /etc/default/locale

  if { [ -z "$3" ] || [ "$3" == 'all' ]; } && { [ "$setupmodule" == 'system' ] || [[ "$setupmodule" == system-* ]]; }; then
    __confirm "$action"

    # Setting up an individual system module for all systems
    while read system; do
      run "$setupmodule" "$action" "$system" "${@:4}"
    done < <(setting '.systems[]')

    # Exceptions for the "retropie" system
    if [ "$setupmodule" == 'system-docs' ]; then
      run "$setupmodule" "$action" retropie
    fi
  else
    # Setting up an individual module
    run "$setupmodule" "$action" "${@:3}"
  fi
}

__confirm() {
  local action=$1

  if [ "$CONFIRM" == 'false' ]; then
    return
  fi

  if [[ "$action" =~ ^(uninstall|remove) ]]; then
    # Confirm on remove/uninstall instead of asking for each individual setupmodule
    read -p "Are you sure? (y/n) " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo 'Aborted.'
      exit 1
    fi

    export CONFIRM=false
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

  local script_file=$(first_path "{bin_dir}/setup/$setupmodule.sh")
  if [ -z "$script_file" ]; then
    echo "Setup module not found: $setupmodule"
    return 1
  fi

  "$script_file" "$action" "${@:3}"
}

main() {
  local action="$1"
  local setupmodule="$2"

  if [ -z "$setupmodule" ] || [ "$setupmodule" == 'all' ]; then
    setup_all "$action"
  elif [[ "$setupmodule" == *~* ]]; then
    IFS=~ read -ra range <<< "$setupmodule"
    setup_all "$action" from_setupmodule="${range[0]}" to_setupmodule="${range[1]}"
  else
    setup "$action" "$setupmodule" "${@:3}"
  fi

  >&2 echo 'Done!'
}

if [[ $# -lt 1 ]]; then
  usage
fi

main "$@"
