#!/usr/bin/env bash

# Runs the supermodel3 emulator, automatically updated the display resolution
# to match the game's rendered resolution in order to be displayed in full
# screen without impacting performance.

run() {
  local bin_path=$1
  local rom_path=$2

  local bin_dir=$(dirname "$bin_path")
  local config_path="$bin_dir/Config/Supermodel.ini"

  set_resolution "$config_path" "$rom_path"

  # Supermodel looks for configurations relative to the current working directory.
  # Rather than force everything to be in the home directory, we switch to the
  # location of the emulator.
  pushd "$bin_dir"
  "$bin_path" "$rom_path"
  popd
}

set_resolution() {
  local config_path=$1
  local rom_path=$2

  local rom_filename=${rom_path##*/}
  local rom_name=${rom_filename%.*}

  # Get resolution that the game is going to be rendered in
  local game_x_resolution=$(__config_get "$rom_name" XResolution || __config_get Global XResolution || echo 496)
  local game_y_resolution=$(__config_get "$rom_name" YResolution || __config_get Global YResolution || echo 384)
  local game_pixels=$(( $game_x_resolution *  $game_y_resolution ))

  # Get display's current resolution
  local current_resolution=($(xrandr | grep -oE 'current [0-9]+ x [0-9]+' | grep -oE '[0-9]+'))
  local current_x_resolution=${current_resolution[0]}
  local current_y_resolution=${current_resolution[1]}

  # Identify a target resolution that is as close as possible to the game resolution.
  # This ensures that the rendered game isn't just a tiny box and fills up as much of
  # the display pixels as possible.
  local target_x_resolution=$current_x_resolution
  local target_y_resolution=$current_y_resolution
  local target_unused_pixels=$(( $target_x_resolution * $target_y_resolution - $game_pixels ))

  while read x_resolution y_resolution; do
    local unused_pixels=$(( $x_resolution * $y_resolution - $game_pixels ))

    # Check: Resolution is greater than game resolution
    if [ $x_resolution -lt $game_x_resolution ] || [ $y_resolution -lt $game_y_resolution ]; then
      continue
    fi

    # Check: One of the resolutions is less
    if [ $x_resolution -gt $target_x_resolution ] && [ $y_resolution -gt $target_y_resolution ]; then
      continue
    fi

    # Check: Both resolutions are less or fewer unused pixels
    if [ $x_resolution -lt $target_x_resolution ] && [ $y_resolution -lt $target_y_resolution ] || [ $unused_pixels -lt $target_unused_pixels ]; then
      target_x_resolution=$x_resolution
      target_y_resolution=$y_resolution
    fi
  done < <(xrandr | grep -oE '^ *[0-9]+x[0-9]+' | sed 's/x/ /g')

  if [ "$target_x_resolution" != "$current_x_resolution" ]; then
    xrandr -s "${target_x_resolution}x${target_y_resolution}"
  fi
}

__config_get() {
  local section=$2
  local key=$3
  if [ $# -gt 3 ]; then local "${@:4}"; fi

  if [ ! -f "$config_path" ]; then
    return 1
  fi

  # Find the relevant section
  local section_content=$(sed -n "/^\[$section\]/,/^\[/p" "$config_path")

  # Find the associated key within that section
  if echo "$section_content" | grep -Eq "^[ \t]*$key[ \t]*="; then
    echo "$section_content" | sed -n "s/^[ \t]*$key[ \t]*=[ \t]*\"*\([^\"\r]*\)\"*.*/\1/p" | tail -n 1
  else
    return 1
  fi
}

run "${@}"
