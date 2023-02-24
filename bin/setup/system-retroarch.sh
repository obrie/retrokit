#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

setup_module_id='system-retroarch'
setup_module_desc='System-specific Retroarch configurations and core options overrides'
setup_module_reconfigure_after_update=true

configure() {
  restore

  __configure_system_config
  __configure_emulator_configs
  __configure_emulator_remappings
  __configure_core_options
}

# System configuration overrides
__configure_system_config() {
  # System configs
  ini_merge '{system_config_dir}/retroarch.cfg' "$retropie_system_config_dir/retroarch.cfg"

  # Shared system configs
  while read shared_config_name; do
    ini_merge "{system_config_dir}/$shared_config_name.cfg" "$retropie_system_config_dir/$shared_config_name.cfg" backup=false
  done < <(each_path '{system_config_dir}' find '{}' -mindepth 1 -maxdepth 1 -name 'retroarch-*.cfg' -not -name 'retroarch-core-options*.cfg' -exec basename {} .cfg \; | sort | uniq)
}

# Emulator configuration overrides
__configure_emulator_configs() {
  local retroarch_config_dir=$(get_retroarch_path 'rgui_config_directory')

  while read -r library_name; do
    local source_dir="{system_config_dir}/retroarch/$library_name"
    local source_file="$source_dir/$library_name.cfg"
    local target_dir="$retroarch_config_dir/$library_name"
    local target_file="$target_dir/$library_name.cfg"
    if [ ! -d "$source_dir" ]; then
      continue
    fi

    ini_merge "$source_file" "$target_file"

    # Shared emulator configs
    while read shared_config_name; do
      ini_merge "$source_dir/$shared_config_name.cfg" "$target_dir/$shared_config_name.cfg" backup=false
    done < <(each_path "$source_dir" find '{}' -mindepth 1 -maxdepth 1 -name "$library_name-*.cfg" -exec basename {} .cfg \; | sort | uniq)
  done < <(get_core_library_names)
}

# Emulator control remapping overrides
__configure_emulator_remappings() {
  local retroarch_remapping_dir=$(get_retroarch_path 'input_remapping_directory')
  local retroarch_remapping_dir=${retroarch_remapping_dir%/}

  while read -r library_name; do
    local source_file="{system_config_dir}/retroarch/$library_name/$library_name.rmp"
    local target_file="$retroarch_remapping_dir/$library_name/$library_name.rmp"

    ini_merge "$source_file" "$target_file"
  done < <(get_core_library_names)
}

# System core options
__configure_core_options() {
  local global_core_options_file=${retroarch_path_defaults['core_options_path']}
  local core_options_file=$(get_retroarch_path 'core_options_path')

  if [ "$global_core_options_file" == "$core_options_file" ]; then
    echo 'Skipping core options overrides (core_options_file is missing)'
    return
  fi

  # Start with an empty core options -- we'll build it up based on other files
  truncate -s0 "$core_options_file"

  local tmp_core_options_file=$(mktemp -p "$tmp_ephemeral_dir")
  while read core_option_prefix; do
    # Global defaults from RetroPie
    echo "Merging $core_option_prefix core options from $global_core_options_file to $core_options_file"
    grep -E "^$core_option_prefix[\-_]" "$global_core_options_file" > "$tmp_core_options_file" || true
    if [ -s "$tmp_core_options_file" ]; then
      ini_merge "$tmp_core_options_file" "$core_options_file" backup=false >/dev/null
    fi

    # retrokit global overrides
    echo "Merging $core_option_prefix global overrides to $core_options_file"
    each_path '{config_dir}/retroarch/retroarch-core-options.cfg' cat '{}' | grep -E "^$core_option_prefix[\-_]" > "$tmp_core_options_file" || true
    if [ -s "$tmp_core_options_file" ]; then
      ini_merge "$tmp_core_options_file" "$core_options_file" backup=false >/dev/null
    fi
  done < <(system_setting 'select(.emulators) | .emulators[] | select(.core_name) | .core_option_prefix // .core_name' | uniq)

  # Merge in system-specific overrides
  ini_merge '{system_config_dir}/retroarch-core-options.cfg' "$core_options_file" backup=false
  sort -o "$core_options_file" "$core_options_file"
}

restore() {
  # Remove system retroarch core options files
  local global_core_options_file=${retroarch_path_defaults['core_options_path']}
  local core_options_file=$(get_retroarch_path 'core_options_path')
  if [ "$global_core_options_file" != "$core_options_file" ]; then
    rm -fv "$core_options_file"
  fi

  # Restore emulator retroarch configs
  local retroarch_config_dir=$(get_retroarch_path 'rgui_config_directory')
  while read -r library_name; do
    local library_dir="$retroarch_config_dir/$library_name"
    if [ ! -d "$library_dir" ]; then
      continue
    fi

    restore_file "$library_dir/$library_name.cfg" delete_src=true
    find "$library_dir" -mindepth 1 -maxdepth 1 -name "$library_name-*.cfg" -exec rm -fv '{}' +
  done < <(get_core_library_names)

  # Restore system retroarch config
  restore_file "$retropie_system_config_dir/retroarch.cfg" delete_src=true
  find "$retropie_system_config_dir" -mindepth 1 -maxdepth 1 -name 'retroarch-*.cfg' -not -name 'retroarch-core-options*.cfg' -exec rm -fv '{}' +
}

setup "${@}"
