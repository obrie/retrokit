#!/bin/bash

launch_manualkit() {
  local system=$1
  local emulator=$2
  local rom_path=$3

  # Look up expected path to the manual
  local rom_filename=$(basename "$rom_path")
  local rom_name=${rom_filename%.*}
  local manual_path="$HOME/.emulationstation/downloaded_media/$system/manuals/$rom_name.pdf"

  # Look up reference guid
  local reference_path="$HOME/.emulationstation/downloaded_media/$system/docs/$rom_name.pdf"
  if [ ! -f "$reference_path" ]; then
    reference_path="$HOME/.emulationstation/downloaded_media/$system/docs/default.pdf"
  fi

  # Start up manualkit
  if [ -f /opt/retropie/supplementary/manualkit/cli.py ]; then
    sudo python3 /opt/retropie/supplementary/manualkit/cli.py "$manual_path" /opt/retropie/configs/all/manualkit.conf --supplementary-pdf "$reference_path" --track-emulator &
  fi
}

launch_manualkit "${@}" </dev/null &>/dev/null
