#!/bin/bash

# Determine ROM name
# NOTE: The ROM path is escaped already by EmulationStation.  This is the only
# script event in which the path is escaped.
eval rom_path=$1
rom_filename=${rom_path##*/}
rom_name=${rom_filename%.*}

# Determine system name.  We can't use $1 because this will be "all" or "favorites"
# when browsing those collections.  We instead need to rely on the rom path.
system_relative_dir=${rom_path/"$HOME/RetroPie/roms/"/}
system=${system_relative_dir%%/*}

media_dir="$HOME/.emulationstation/downloaded_media/$system"
rom_manual_path="$media_dir/manuals/$rom_name.pdf"

# Determine which reference guide to try to show
if [ -f "$media_dir/docs/$rom_name.pdf" ]; then
  rom_reference_path="$media_dir/docs/$rom_name.pdf"
else
  rom_reference_path="$media_dir/docs/default.pdf"
fi

# Swap the manual with the reference for arcade games since the manual tends to have less information
if [ "$system" == 'arcade' ]; then
  orig_rom_manual_path=$rom_manual_path
  rom_manual_path=$rom_reference_path
  rom_reference_path=$orig_rom_manual_path
fi

exec 4<>/opt/retropie/configs/all/manualkit.fifo
>&4 echo \
  'hide'$'\n' \
  'reset_display'$'\n' \
  'load'$'\t'"$rom_manual_path"$'\t'"$rom_reference_path"$'\t''true'$'\n' \
  'set_profile'$'\t''emulator'
