#!/bin/bash

declare -Ag arcade_controls
while IFS=, read rom_name buttons; do
  if [ -z "${arcade_controls[$rom_name]}" ]; then
    arcade_controls["$rom_name"]="$buttons"
  fi
done < <(each_path '{system_docs_dir}/controls.csv' cat '{}' | tac)

# Determines whether the given ROM has any doc overrides
__has_rom_overrides() {
  local core_options_path=$1
  local name=$2
  local parent_name=$3

  [ -n "${arcade_controls[$name]}" ] || { [ -n "$parent_name" ] && [ -n "${arcade_controls[$parent_name]}" ]; }
}

# Add arcade-specific controls
__add_system_extensions() {
  local core_options_path=$1
  local name=$2
  local parent_name=$3

  # Look up the layout
  local layout_button_index=($(jq -r '.controls .layout .ids[]' "$(first_path '{system_docs_dir}/doc.json')"))

  # Read the button names for this game or use system defaults
  local buttons
  if [ -n "$name" ]; then
    local buttons_csv=${arcade_controls[$name]:-${arcade_controls[$parent_name]}}
    IFS=, read -r -a buttons <<< "$buttons_csv"
  else
    buttons=($(jq -r '.controls .layout .buttons[]' "$(first_path '{system_docs_dir}/doc.json')"))
  fi

  # Build top row
  local html=""
  for column in $(seq 1 3); do
    local button_index=${layout_button_index[column-1]}
    html="${html}$(__create_button 'top' $column "${buttons[button_index-1]}")"
  done

  # Build bottom row
  for column in $(seq 1 3); do
    local button_index=${layout_button_index[column+2]}
    html="${html}$(__create_button 'bottom' $column "${buttons[button_index-1]}")"
  done

  __edit_json '.controls.description' "$html" "$controls_file"
}

# Creates the html for the button at the given row / column in the layout
__create_button() {
  local row=$1
  local column=$2
  local value=$3

  local color
  if [ -n "$value" ]; then
    color='green'
  else
    color='black'
  fi

  echo "<img class=\"button button-$row$column\" src=\"systems/arcade/button-$color.png\"><span class=\"description button-$row$column\">$value</span>"
}
