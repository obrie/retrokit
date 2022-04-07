#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-docs-common.sh"

setup_module_id='system-roms-docs'
setup_module_desc='ROM reference sheet builder'

build() {
  load_emulator_data
  if ! __source_system_extensions; then
    return
  fi

  local retroarch_config_dir=$(get_retroarch_path 'rgui_config_directory')

  # Start with a base controls file
  local base_controls_file=$controls_file
  echo '{}' > "$base_controls_file"
  __add_system_theme
  __add_keyboard_controls
  __add_hotkey_controls

  # Redefine the controls file for ROMs
  controls_file="$tmp_ephemeral_dir/rom_controls.json"

  while IFS='»' read name parent_name emulator; do
    emulator=${emulator:-default}
    local library_name=${emulators["$emulator/library_name"]}
    local core_options_file="$retroarch_config_dir/$library_name/$name.opt"

    # Check if the ROM actually has overrides before we build documentation for it
    if ! __has_rom_overrides "$core_options_file" "$name" "$parent_name"; then
      continue
    fi

    echo "[$name] Building documentation..."
    local output_path="$HOME/.emulationstation/downloaded_media/$system/docs/$name.pdf"
    mkdir -p "$(dirname "$output_path")"

    # Build the PDF
    cp "$base_controls_file" "$controls_file"
    __add_system_extensions "$core_options_file" "$name" "$parent_name"
    __build_pdf "$output_path"
  done < <(romkit_cache_list | jq -r '[.name, .parent.name, .emulator] | join("»")')
}

remove() {
  find "$HOME/.emulationstation/downloaded_media/$system/docs" -name '*.pdf' -not -name 'default.pdf' -exec rm -fv '{}' +
}

setup "${@}"
