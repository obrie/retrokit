#!/bin/bash

# Add nes-specific controls
__add_system_extensions() {
  local core_options_file=$1
  local edit_args=()

  # Turbo controls
  local turbo_enabled=$(crudini --get "$core_options_file" '' pce_Turbo_Toggling 2>/dev/null | tr -d '"')
  if [ "$turbo_enabled" == 'enabled' ]; then
    edit_args+=(
      '.controls.retropad."x"' 'Turbo A'
      '.controls.retropad."y"' 'Turbo B'
    )
  fi

  if [ ${#edit_args[@]} -gt 0 ]; then
    json_edit "$doc_data_file" "${edit_args[@]}"
  fi
}