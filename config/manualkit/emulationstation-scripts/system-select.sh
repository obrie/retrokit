#!/bin/bash

system=$1

media_dir="$HOME/.emulationstation/downloaded_media"
if [ -d "$media_dir/$system" ]; then
  system_reference_path="$media_dir/$system/docs/default.pdf"
else
  system_reference_path="$media_dir/retropie/docs/default.pdf"
fi

exec 4<>/var/run/manualkit.fifo
>&4 echo \
  'load'$'\t'"$system_reference_path"$'\n' \
  'set_profile'$'\t''frontend'
