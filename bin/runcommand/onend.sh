#!/bin/bash

if [ -d /opt/retropie/configs/all/runcommand.d ]; then
  for runcommand_app in /opt/retropie/configs/all/runcommand.d/*; do
    if [ -f "$runcommand_app/onend.sh" ]; then
      "$runcommand_app/onend.sh" "${@}"
    fi
  done
fi
