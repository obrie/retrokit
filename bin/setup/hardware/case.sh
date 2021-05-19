#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../common.sh"

model=$(setting '.hardware.case.model')
if [ -n "$model" ]; then
  "$dir/cases/$model.sh" "${@}"
fi
