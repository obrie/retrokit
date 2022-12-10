#!/bin/bash

retroarch_bin=$1
mess_lib=$2
retroarch_config=$3
retroarch_dir=$(dirname "$retroarch_config")
mess_system=$4
bios_dir=$5
read -a mess_args <<< "$6"
rom_path=$7
rom_dir=$(dirname "$rom_path")

# Generate parameters for MESS cmd file
mess_cmd=("$mess_system" -readconfig -inipath "\"$retroarch_dir/mame/ini\"" -rp "\"$bios_dir;$rom_dir\"" -artpath "\"$retroarch_dir/mame/artwork\"" -cfg_directory "\"$retroarch_dir/mame/cfg\"")
for arg in "${mess_args[@]}"; do
  mess_cmd+=( \""$arg"\" )
done
mess_cmd+=( \""$rom_path"\" )

# Define path based on where the ROM exists.  We put it in the same folder
# using the same basename so that configurations get persisted correctly
# between launches
rom_filename=$(basename "$rom_path")
rom_name=${rom_filename%.*}
cmd_path="$rom_dir/$rom_name.cmd"

# Ensure command file is cleaned up regardless of how this script exits
on_exit() {
  rm -fv "$cmd_path"
}
trap "on_exit" EXIT

echo "MESS command: ${mess_cmd[@]}"
echo "${mess_cmd[@]}" > "$cmd_path"

set -- "$retroarch_bin" --config "$retroarch_config" -L "$mess_lib" ${@:8} "$cmd_path"
echo "Launching: $@"
"$@"
