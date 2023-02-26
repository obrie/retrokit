#!/bin/bash

if [ "$2" == 'retropie' ]; then
  export SKIP_SYSTEM_CHECK=true
fi

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-docs-common.sh"

setup_module_id='system-docs'
setup_module_desc='System reference sheet builder'

es_system_docs_dir="$HOME/.emulationstation/downloaded_media/$system/docs"

build() {
  if ! any_path_exists '{system_docs_dir}/doc.json'; then
    echo 'No documentation configured'
    return
  fi

  local staging_file=$(mktemp -p "$tmp_dir")
  local output_file="$es_system_docs_dir/default.pdf"
  if [ -f "$output_file" ] && [ "$FORCE_UPDATE" != 'true' ]; then
    echo "Documentation already built for $system"
    return
  fi

  __source_system_extensions || true
  __add_hrefs
  __add_system_theme
  __add_keyboard_controls
  __add_hotkey_controls
  __add_system_extensions "$(get_retroarch_path 'core_options_path')"
  __build_pdf "$staging_file"

  # Move PDF to final location
  mkdir -p "$(dirname "$output_file")"
  mv -v "$staging_file" "$output_file"
}

remove() {
  rm -rfv "$es_system_docs_dir"
}

setup "${@}"
