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
  local base_doc_data_file=$doc_data_file
  __add_hrefs
  __add_system_theme
  __add_keyboard_controls
  __add_hotkey_controls

  # Redefine the controls file for ROMs
  doc_data_file=$(mktemp -p "$tmp_ephemeral_dir" --suffix=.json)

  while IFS='»' read name group_name emulator; do
    emulator=${emulator:-default}
    local library_name=${emulators["$emulator/library_name"]}
    local core_options_file="$retroarch_config_dir/$library_name/$name.opt"

    # Check if the ROM actually has overrides before we build documentation for it
    if ! __has_rom_overrides "$core_options_file" "$name" "$group_name"; then
      continue
    fi

    local staging_path=$(mktemp -p "$tmp_ephemeral_dir")
    local output_path="$HOME/.emulationstation/downloaded_media/$system/docs/$name.pdf"
    if [ -f "$output_path" ] && [ "$FORCE_UPDATE" != 'true' ]; then
      echo "[$name] Already built documentation"
      continue
    fi

    echo "[$name] Building documentation..."

    # Build the PDF
    cp "$base_doc_data_file" "$doc_data_file"
    __add_system_extensions "$core_options_file" "$name" "$group_name" "$emulator"
    __build_pdf "$staging_path"

    # Move PDF to final location
    mkdir -p "$(dirname "$output_path")"
    mv "$staging_path" "$output_path"
  done < <(romkit_cache_list | jq -r '[.name, .group.name, .emulator] | join("»")')
}

remove() {
  find "$HOME/.emulationstation/downloaded_media/$system/docs" -name '*.pdf' -not -name 'default.pdf' -exec rm -fv '{}' +
}

setup "${@}"
