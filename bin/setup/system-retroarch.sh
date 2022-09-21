#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

setup_module_id='system-retroarch'
setup_module_desc='System-specific Retroarch configurations and core options overrides'
setup_module_reconfigure_after_update=true

configure() {
  __configure_system_config
  __configure_emulator_configs
  __configure_emulator_remappings
  __configure_core_options
}

# System configuration overrides
__configure_system_config() {
  ini_merge '{system_config_dir}/retroarch.cfg' "$retropie_system_config_dir/retroarch.cfg"
}

# Emulator configuration overrides
__configure_emulator_configs() {
  local retroarch_config_dir=$(get_retroarch_path 'rgui_config_directory')

  while read -r library_name; do
    local source_path="{system_config_dir}/retroarch/$library_name/$library_name.cfg"
    local target_path="$retroarch_config_dir/$library_name/$library_name.cfg"

    if any_path_exists "$source_path"; then
      ini_merge "$source_path" "$target_path"
    else
      rm -fv "$target_path"
    fi
  done < <(get_core_library_names)
}

# Emulator control remapping overrides
__configure_emulator_remappings() {
  local retroarch_remapping_dir=$(get_retroarch_path 'input_remapping_directory')
  local retroarch_remapping_dir=${retroarch_remapping_dir%/}

  while read -r library_name; do
    local source_path="{system_config_dir}/retroarch/$library_name/$library_name.rmp"
    local target_path="$retroarch_remapping_dir/$library_name/$library_name.rmp"

    if any_path_exists "$source_path"; then
      ini_merge "$source_path" "$target_path"
    else
      rm -fv "$target_path"
    fi
  done < <(get_core_library_names)
}

# System core options
__configure_core_options() {
  local global_core_options_path=${retroarch_path_defaults['core_options_path']}
  local core_options_path=$(get_retroarch_path 'core_options_path')

  if [ "$global_core_options_path" == "$core_options_path" ]; then
    echo 'Skipping core options overrides (core_options_path is missing)'
    return
  fi

  # Start with an empty core options -- we'll build it up based on other files
  truncate -s0 "$core_options_path"

  local tmp_core_options_path=$(mktemp -p "$tmp_ephemeral_dir")
  while read core_option_prefix; do
    # Global defaults from RetroPie
    echo "Merging $core_option_prefix core options from $global_core_options_path to $core_options_path"
    grep -E "^$core_option_prefix[\-_]" "$global_core_options_path" > "$tmp_core_options_path" || true
    if [ -s "$tmp_core_options_path" ]; then
      ini_merge "$tmp_core_options_path" "$core_options_path" backup=false >/dev/null
    fi

    # retrokit global overrides
    echo "Merging $core_option_prefix global overrides to $core_options_path"
    each_path '{config_dir}/retroarch/retroarch-core-options.cfg' cat '{}' | grep -E "^$core_option_prefix[\-_]" > "$tmp_core_options_path" || true
    if [ -s "$tmp_core_options_path" ]; then
      ini_merge "$tmp_core_options_path" "$core_options_path" backup=false >/dev/null
    fi
  done < <(system_setting 'select(.emulators) | .emulators[] | select(.core_name) | .core_option_prefix // .core_name' | uniq)

  # Merge in system-specific overrides
  ini_merge '{system_config_dir}/retroarch-core-options.cfg' "$core_options_path" backup=false
  sort -o "$core_options_path" "$core_options_path"
}

restore() {
  # Remove system retroarch core options files
  local global_core_options_path=${retroarch_path_defaults['core_options_path']}
  local core_options_path=$(get_retroarch_path 'core_options_path')
  if [ "$global_core_options_path" != "$core_options_path" ]; then
    rm -fv "$core_options_path"
  fi

  # Restore emulator retroarch configs
  local retroarch_config_dir=$(get_retroarch_path 'rgui_config_directory')
  while read -r library_name; do
    restore_file "$retroarch_config_dir/$library_name/$library_name.cfg" delete_src=true
  done < <(get_core_library_names)

  # Restore system retroarch config
  restore_file "$retropie_system_config_dir/retroarch.cfg"
}

setup "$1" "${@:3}"
