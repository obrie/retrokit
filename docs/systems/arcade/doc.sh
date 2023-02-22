#!/bin/bash

declare -Ag arcade_controls
while IFS=$'\t' read group_name buttons; do
  arcade_controls["$group_name"]="$buttons"
done < <(jq -r 'to_entries[] | select(.value.buttons) | [.key, (.value.buttons | join(","))] | @tsv' "$system_data_file")

# Determines whether the given ROM has any doc overrides
__has_rom_overrides() {
  local core_options_file=$1
  local name=$2
  local group_name=$3

  [ -n "${arcade_controls[$name]}" ] || { [ -n "$group_name" ] && [ -n "${arcade_controls[$group_name]}" ]; }
}

# Add arcade-specific controls
__add_system_extensions() {
  local core_options_file=$1
  local name=$2
  local group_name=$3
  local emulator=$4

  # Read the button names for this game or use system defaults
  local button_actions=()
  local button_class
  if [ -n "$name" ]; then
    local buttons_csv=${arcade_controls[$name]:-${arcade_controls[$group_name]}}
    IFS=, read -r -a button_actions <<< "$buttons_csv"
  else
    button_class='button-enabled'
  fi

  # Look up the control panel layout
  local control_panel_layout=$(jq -r '.controls .layout .panel' "$doc_data_file")
  local control_panel_labels=($(jq -r '.controls .layout .labels[]' "$doc_data_file"))

  # Look up the button mapping layout
  local button_mappings=$(jq -r "(.controls .layout .roms | to_entries[] | select(.value | index(\"$group_name\")) | .key) // (.controls .layout .emulators | to_entries[] | select(.value | index(\"$emulator\")) | .key) // (.controls .layout .emulators | to_entries[] | select(.value | index(\"default\")) | .key)" "$doc_data_file")

  # Map button names to the corresponding actions based on their mapping index
  # (i.e. the index of each button within $button_mappings)
  # 
  # The controls.csv maps BUTTON_1, BUTTON_2, etc. and the rom/emulator layout
  # maps the panel button name to the action by index.
  declare -A button_name_actions
  for (( i=0; i<${#button_mappings}; i++ )); do
    local button_name=${button_mappings:$i:1}
    local button_action=${button_actions[$i]}

    button_name_actions[$button_name]=$button_action
  done

  # Build top row
  local html=""
  for column in $(seq 1 3); do
    local control_panel_name=${control_panel_layout:column-1:1}
    local control_panel_label=${control_panel_labels[column-1]}
    local button_action=${button_name_actions[$control_panel_name]}

    html="${html}$(__create_button 'top' $column "$control_panel_label" "$button_action" "$button_class")"
  done

  # Build bottom row
  for column in $(seq 1 3); do
    local control_panel_name=${control_panel_layout:column+2:1}
    local control_panel_label=${control_panel_labels[column+2]}
    local button_action=${button_name_actions[$control_panel_name]}

    html="${html}$(__create_button 'bottom' $column "$control_panel_label" "$button_action" "$button_class")"
  done

  html="<ol id=\"controller-retropad-buttons\">$html</ol>"
  json_edit "$doc_data_file" '.images.retropad_html' "$html"
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
