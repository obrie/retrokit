#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

export SKIP_DEPS=true

while read setupmodule; do
  if [[ "$setupmodule" == system-roms-* ]] || [[ "$setupmodule" == systems/$system/roms-* ]]; then
    print_heading "Running $1 for $setupmodule"
    "$dir/$setupmodule.sh" "${@}"
  fi
done < <(list_setupmodules)
