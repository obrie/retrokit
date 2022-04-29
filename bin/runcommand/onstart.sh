#!/bin/bash

if [ -d /opt/retropie/configs/all/runcommand.d ]; then
  for runcommand_dir in /opt/retropie/configs/all/runcommand.d/*; do
    if [ -f "$runcommand_dir/onstart.sh" ]; then
      "$runcommand_dir/onstart.sh" "${@}"
    fi
  done
fi
