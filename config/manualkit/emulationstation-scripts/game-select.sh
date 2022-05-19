#!/bin/bash

# Determine ROM name
rom_path=$2
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

exec 4<>/opt/retropie/configs/all/manualkit.fifo
>&4 echo \
  'load'$'\t'"$rom_manual_path"$'\t'"$rom_reference_path"$'\n' \
  'set_profile'$'\t''frontend'
