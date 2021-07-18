#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

# Global configuration overrides
install_config() {
  ini_merge "$system_config_dir/retroarch.cfg" "$retropie_system_config_dir/retroarch.cfg"
}

install_emulator_config() {
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

# Global core options
install_core_options() {
  local global_core_options_path=${retroarch_path_defaults['core_options_path']}
  local core_options_path=$(get_retroarch_path 'core_options_path')

  # Use the global defaults as the initial file
  cp -v "$global_core_options_path" "$core_options_path"

  if [ -f "$system_config_dir/retroarch-core-options.cfg" ]; then
    echo "Merging ini $system_config_dir/retroarch-core-options.cfg to $core_options_path"
    crudini --merge "$core_options_path" < "$system_config_dir/retroarch-core-options.cfg"
  fi

  # Reinstall the game-specific retroarch core options for this system.
  # Yes, this might mean we install game-specific core options multiple
  # times, but it also means we don't have to worry about remembering to
  # re-run system-roms-retroarch after running this setupmodule
  if [ -z "$SKIP_DEPS" ] && has_setupmodule 'system-roms-retroarch'; then
    "$bin_dir/setup.sh" install_retroarch_core_options system-roms-retroarch "$system"
  fi
}

install() {
  install_config
  install_emulator_config
  install_core_options
}

uninstall() {
  # Remove system-specific retroarch core options files
  local core_options_path=$(get_retroarch_path 'core_options_path')
  rm -fv "$core_options_path"

  # Restore emulator-specific retroarch configs
  local retroarch_config_dir=$(get_retroarch_path 'rgui_config_directory')
  while read -r library_name; do
    restore "$retroarch_config_dir/$library_name/$library_name.cfg" delete_src=true
  done < <(get_core_library_names)

  # Restore system-specific retroarch config
  restore "$retropie_system_config_dir/retroarch.cfg"
}

"$1" "${@:3}"
