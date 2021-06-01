#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

while read -r setupmodule; do
  if [[ "$setupmodule" == system-* ]] || [[ "$setupmodule" == systems/$system/* ]]; then
    print_heading "Running $1 for $setupmodule"
    "$dir/$setupmodule.sh" "${@}"
  fi
done < <(setting '.modules[]')
