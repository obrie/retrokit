#!/bin/bash

launch_manualkit() {
  local system=$1
  local emulator=$2
  local rom_path=$3

  # Look up expected path to the manual
  local rom_filename=$(basename "$rom_path")
  local rom_name=${rom_filename%.*}
  local manual_file="$HOME/.emulationstation/downloaded_media/$system/manuals/$rom_name.pdf"

  # Look up reference guid
  local reference_file="$HOME/.emulationstation/downloaded_media/$system/docs/$rom_name.pdf"
  if [ ! -f "$reference_file" ]; then
    reference_file="$HOME/.emulationstation/downloaded_media/$system/docs/default.pdf"
  fi

  # Start up manualkit
  local runcommand_pid=$(ps aux | grep 'runcommand.sh' | grep -Ev grep | awk '/ +/ { print $2 }' | head -n 1)
  sudo python3 /opt/retropie/supplementary/manualkit/cli.py /opt/retropie/configs/all/manualkit.cfg --profile emulator --pdf "$manual_file" --supplementary-pdf "$reference_file" --track-pid $runcommand_pid &
}

launch_manualkit "${@}" </dev/null &>/dev/null
