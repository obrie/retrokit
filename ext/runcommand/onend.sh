#!/bin/bash

runcommand_dir=/opt/retropie/configs/all/runcommand.d

if [ -d "$runcommand_dir" ]; then
  for runcommand_subdir in "$runcommand_dir/"*; do
    if [ -f "$runcommand_subdir/onend.sh" ]; then
      "$runcommand_subdir/onend.sh" "${@}"
    fi
  done
fi
