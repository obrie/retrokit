#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

while read -r setupmodule; do
  if [[ "$setupmodule" == system-* ]] || [[ "$setupmodule" == systems/$system/* ]]; then
    "$dir/setup/$setupmodule.sh" "${@}"
  fi
done < <(setting '.modules[]')
