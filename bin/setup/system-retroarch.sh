#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

setup_module_id='system-retroarch'
setup_module_desc='System-specific Retroarch configurations and core options overrides'
setup_module_reconfigure_after_update=true

configure() {
  __configure_system_config
  __configure_emulator_configs
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

# System core options
__configure_core_options() {
  local global_core_options_path=${retroarch_path_defaults['core_options_path']}
  local core_options_path=$(get_retroarch_path 'core_options_path')

  if [ "$global_core_options_path" == "$core_options_path" ]; then
    echo 'Skipping core options overrides (core_options_path is missing)'
    return
  fi

  # Start with an empty core options -- we'll build it up based on other files
  rm -fv "$core_options_path"

  local tmp_core_options_path=$(mktemp -p "$tmp_ephemeral_dir")
  while read core_name; do
    # Global defaults from RetroPie
    echo "Merging $core_name core options from $global_core_options_path to $core_options_path"
    grep -E "^$core_name" "$global_core_options_path" > "$tmp_core_options_path" || true
    if [ -s "$tmp_core_options_path" ]; then
      ini_merge "$tmp_core_options_path" "$core_options_path" backup=false >/dev/null
    fi

    # retrokit global overrides
    echo "Merging $core_name global overrides to $core_options_path"
    each_path '{config_dir}/retroarch/retroarch-core-options.cfg' cat '{}' | grep -E "^$core_name" > "$tmp_core_options_path" || true
    if [ -s "$tmp_core_options_path" ]; then
      ini_merge "$tmp_core_options_path" "$core_options_path" backup=false >/dev/null
    fi
  done < <(system_setting 'select(.emulators) | .emulators[] | select(.core_name) | .core_name' | uniq)

  # Merge in system-specific overrides
  ini_merge '{system_config_dir}/retroarch-core-options.cfg' "$core_options_path" backup=false
  sort -o "$core_options_path" "$core_options_path"

  # Reinstall the game-specific retroarch core options for this system.
  # Yes, this might mean we install game-specific core options multiple
  # times, but it also means we don't have to worry about remembering to
  # re-run system-roms-retroarch after running this setupmodule.
  # 
  # This is required because retroarch currently has no concept of reading
  # from multiple core options files.  So, if you have an override at a
  # global / system level, then any rom-specific core options file *also*
  # has to include that configuration.
  after_hook __configure_retroarch_core_options system-roms-retroarch "$system"
}

restore() {
  # Remove system retroarch core options files
  local core_options_path=$(get_retroarch_path 'core_options_path')
  rm -fv "$core_options_path"

  # Restore emulator retroarch configs
  local retroarch_config_dir=$(get_retroarch_path 'rgui_config_directory')
  while read -r library_name; do
    restore_file "$retroarch_config_dir/$library_name/$library_name.cfg" delete_src=true
  done < <(get_core_library_names)

  # Restore system retroarch config
  restore_file "$retropie_system_config_dir/retroarch.cfg"
}

setup "$1" "${@:3}"
