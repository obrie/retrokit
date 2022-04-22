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

  local staging_path="$tmp_ephemeral_dir/doc.pdf"
  local output_path="$HOME/.emulationstation/downloaded_media/$system/docs/default.pdf"
  if [ -f "$output_path" ] && [ "$FORCE_UPDATE" != 'true' ]; then
    echo "Documentation already built for $system"
    return
  fi

  echo '{}' > "$doc_data_file"

  __source_system_extensions || true
  __add_hrefs
  __add_system_theme
  __add_keyboard_controls
  __add_hotkey_controls
  __add_system_extensions "$(get_retroarch_path 'core_options_path')"
  __build_pdf "$staging_path"

  # Move PDF to final location
  mkdir -p "$(dirname "$output_path")"
  mv "$staging_path" "$output_path"
}

remove() {
  rm -rfv "$HOME/.emulationstation/downloaded_media/$system/docs"
}

setup "${@}"
