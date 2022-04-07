#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-docs-common.sh"

setup_module_id='system-docs'
setup_module_desc='System reference sheet builder'

build() {
  if ! any_path_exists '{system_docs_dir}/doc.json'; then
    echo 'No documentation configured'
    return
  fi

  local output_path="$HOME/.emulationstation/downloaded_media/$system/docs/default.pdf"
  mkdir -p "$(dirname "$output_path")"

  echo '{}' > "$controls_file"

  __source_system_extensions || true
  __add_hrefs
  __add_system_theme
  __add_keyboard_controls
  __add_hotkey_controls
  __add_system_extensions "$(get_retroarch_path 'core_options_path')"
  __build_pdf "$output_path"
}

remove() {
  rm -rfv "$HOME/.emulationstation/downloaded_media/$system/docs"
}

setup "${@}"
