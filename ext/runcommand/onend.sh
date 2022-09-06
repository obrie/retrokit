#!/bin/bash

if [ -d /opt/retropie/configs/all/runcommand.d ]; then
  for runcommand_dir in /opt/retropie/configs/all/runcommand.d/*; do
    if [ -f "$runcommand_dir/onend.sh" ]; then
      "$runcommand_dir/onend.sh" "${@}"
    fi
  done
fi
