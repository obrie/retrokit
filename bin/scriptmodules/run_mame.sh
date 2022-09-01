#!/bin/bash

retroarch_bin=$1
mame_lib=$2
mame_version=$3
retroarch_config=$4
retroarch_dir=$(dirname "$retroarch_config")
bios_dir=$5
rom_path=$6
rom_dir=$(dirname "$rom_path")

# Generate parameters for MAME cmd file
mame_cmd=(
  mame
  -samplepath "$rom_dir/mame$mame_version/samples"
  -artpath "$rom_dir/mame$mame_version/artwork"
  -cheatpath "$rom_dir/mame$mame_version/cheat"
  -inipath "$rom_dir/mame$mame_version/ini"
  -hashpath "$rom_dir/mame$mame_version/hash"
  -rompath "$rom_dir"
  \""$rom_path"\"
)

# Define path based on where the ROM exists.  We put it in the same folder
# using the same basename so that configurations get persisted correctly
# between launches
rom_dir=$(dirname "$rom_path")
rom_filename=$(basename "$rom_path")
rom_name=${rom_filename%.*}
cmd_path="$rom_dir/$rom_name.cmd"

# Ensure command file is cleaned up regardless of how this script exits
on_exit() {
  rm -fv "$cmd_path"
}
trap "on_exit" EXIT

echo "MAME command: ${mame_cmd[@]}"
echo "${mame_cmd[@]}" > "$cmd_path"

set -- "$retroarch_bin" --config "$retroarch_config" -L "$mame_lib" ${@:7} "$cmd_path"
echo "Launching: $@"
"$@"


"$emudir/retroarch/bin/retroarch -L $cmd --config $md_conf_root/$system/retroarch.cfg %ROM%"
