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
  local layout_button_names=($(jq -r '.controls .layout .buttons[]' "$(first_path '{system_docs_dir}/doc.json')"))

  # Read the button names for this game or use system defaults
  local button_actions=()
  local button_class
  if [ -n "$name" ]; then
    local buttons_csv=${arcade_controls[$name]:-${arcade_controls[$parent_name]}}
    IFS=, read -r -a button_actions <<< "$buttons_csv"
  else
    button_class='button-enabled'
  fi

  # Build top row
  local html=""
  for column in $(seq 1 3); do
    local button_index=${layout_button_index[column-1]}
    html="${html}$(__create_button 'top' $column "${layout_button_names[button_index-1]}" "${button_actions[button_index-1]}" "$button_class")"
  done

  # Build bottom row
  for column in $(seq 1 3); do
    local button_index=${layout_button_index[column+2]}
    html="${html}$(__create_button 'bottom' $column "${layout_button_names[button_index-1]}" "${button_actions[button_index-1]}" "$button_class")"
  done

  html="<ol id=\"controller-retropad-buttons\">$html</ol>"
  __edit_json '.images.retropad_html' "$html" "$controls_file"
}

# Creates the html for the button at the given row / column in the layout
__create_button() {
  local row=$1
  local column=$2
  local name=$3
  local action=$4
  local button_class=$5

  local html="<li class=\"position-container position-row-$row position-column-$column position-$row$column\"><div class=\"info\"><span class=\"name name-$name\">$name</span>"
  local button_class
  if [ -n "$action" ]; then
    html="$html<span class=\"action\">$action</span>"
    button_class="button-enabled"
  fi

  echo "$html<span class=\"connector\"><span class=\"dot\"></span></span></div><span class=\"button $button_class\"></span></li>"
}
