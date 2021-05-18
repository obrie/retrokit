#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

while read -r setupmodule; do
  if [[ "$setupmodule" == system-roms-* ]] || [[ "$setupmodule" == systems/$system/roms-* ]]; then
    "$dir/$setupmodule.sh" "${@}"
  fi
done < <(setting '.modules[]')
