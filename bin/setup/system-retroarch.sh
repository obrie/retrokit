#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

setup_module_id='system-retroarch'
setup_module_desc='System-specific Retroarch configurations and core options overrides'

configure() {
  __configure_system_config
  __configure_emulator_configs
  __configure_core_options
}

# System configuration overrides
__configure_system_config() {
  ini_merge "$system_config_dir/retroarch.cfg" "$retropie_system_config_dir/retroarch.cfg"
}

# Emulator configuration overrides
__configure_emulator_configs() {
  local retroarch_config_dir=$(get_retroarch_path 'rgui_config_directory')

  while read -r library_name; do
    local source_path="$system_config_dir/retroarch/$library_name/$library_name.cfg"
    local target_path="$retroarch_config_dir/$library_name/$library_name.cfg"

    if [ -f "$source_path" ]; then
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

  # Use the global defaults as the initial file
  cp -v "$global_core_options_path" "$core_options_path"

  if [ -f "$system_config_dir/retroarch-core-options.cfg" ]; then
    echo "Merging ini $system_config_dir/retroarch-core-options.cfg to $core_options_path"
    crudini --merge "$core_options_path" < "$system_config_dir/retroarch-core-options.cfg"
  fi

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
