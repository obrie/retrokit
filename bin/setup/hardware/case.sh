#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../common.sh"

setup_module_id='hardware/case'
setup_module_desc='Hardware setup for cases'

model=$(setting '.hardware.case.model')
if [ -n "$model" ]; then
  "$dir/cases/$model.sh" "${@}"
else
  echo "No setup script available for $model"
fi
