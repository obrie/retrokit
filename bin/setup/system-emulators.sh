#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

setup_module_id='system-emulators'
setup_module_desc='Emulator installation and configuration (including BIOS, defaults, and custom commands)'

retropie_emulators_path="$retropie_system_config_dir/emulators.cfg"
retropie_emulators_backup_path="$retropie_emulators_path.rk-src"

build() {
  __install_emulators
  __download_bios_files
}

# Install emulator packages
__install_emulators() {
  while IFS=$'\t' read -r package emulator build; do
    local package_type='emulators'
    if [[ "$package" == lr-* ]]; then
      package_type='libretrocores'
    fi

    install_retropie_package "$package_type" "$package" "$build"
  done < <(system_setting 'select(.emulators) | .emulators | to_entries[] | [.key, .value.name // .key, .value.build // "binary"] | @tsv')

  if [ "$system" == 'ports' ]; then
    # Ensure ports has been added to the default conf since other tools may
    # add system management menus to it
    sudo $HOME/RetroPie-Setup/retropie_packages.sh emptyports configure
  fi
}

# Install BIOS files required by emulators
__download_bios_files() {
  local bios_dir=$(system_setting '.bios.dir')
  local base_url=$(system_setting '.bios.url')

  while IFS=$'\t' read -r bios_name bios_url_template; do
    local bios_url=$(render_template "$bios_url_template" url="$base_url")
    download "$bios_url" "$bios_dir/$bios_name"
  done < <(system_setting 'select(.bios) | .bios.files | to_entries[] | [.key, .value] | @tsv')
}

# Re-runs the `configure` action for all RetroPie packages used by the system
reconfigure_packages() {
  # Restore original configurations
  __reconfigure_packages_hook before_retropie_reconfigure

  # Reconfigure packages for all emulators set up in this system
  while read -r package; do
    configure_retropie_package "$package"
  done < <(system_setting 'select(.emulators) | .emulators | keys[]')

  # Re-apply configuration overrides
  __reconfigure_packages_hook after_retropie_reconfigure
}

# Runs the reconfigure hook for this script, system-retroarch, and any system-specific setup
# script that's configured to handle package reconfigurations
__reconfigure_packages_hook() {
  local hook=$1

  # Run our hook
  "$hook"

  # Run external hooks
  while read setupmodule; do
    "$bin_dir/setup.sh" "$hook" "$setupmodule" "$system"
  done < <(list_setupmodules | grep -E "^system-retroarch$|systems/$system")
}

# Configure emulator settings
configure() {
  # First, restore any emulators we previously overrode
  restore

  # Back up the emulators we're going to override
  __backup_emulator 'default'
  while read -r emulator; do
    __backup_emulator "$emulator"
  done < <(each_path '{system_config_dir}/emulators.cfg' ini_get '{}' '')

  # Set default emulator
  local default_emulator=$(system_setting 'select(.emulators) | .emulators | to_entries[] | select(.value.default == true) | .value.name // .key')
  crudini --set "$retropie_emulators_path" '' 'default' "\"$default_emulator\""

  # Additional emulator settings
  ini_merge '{system_config_dir}/emulators.cfg' "$retropie_emulators_path" backup=false
}

# Backs up the given emulator configuration
__backup_emulator() {
  local emulator=$1
  local cmd=$(crudini --get "$retropie_emulators_path" '' "$emulator" 2>/dev/null)

  crudini --set "$retropie_emulators_backup_path" '' "$emulator" "$cmd"
}

restore() {
  if [ -f "$retropie_emulators_backup_path" ]; then
    # Reset (or delete) the emulator commands that were backed up
    while read -r emulator; do
      local cmd=$(crudini --get "$retropie_emulators_backup_path" '' "$emulator")
      if [ -z "$cmd" ]; then
        crudini --del "$retropie_emulators_path" '' "$emulator"
      else
        crudini --set "$retropie_emulators_path" '' "$emulator" "$cmd"
      fi
    done < <(crudini --get "$retropie_emulators_backup_path" '')

    # Remove the backup since we're now fully restored
    rm -v "$retropie_emulators_backup_path"
  fi
}

remove() {
  # Remove bios files
  local bios_dir=$(system_setting '.bios.dir')
  while read -r bios_name; do
    rm -fv "$bios_dir/$bios_name"
  done < <(system_setting 'select(.bios) | .bios.files | keys[]')

  # Uninstall emulators (this will automatically change the default if applicable)
  while read -r package; do
    uninstall_retropie_package "$package" || true
  done < <(system_setting 'select(.emulators) | .emulators | keys[]')
}

setup "${@}"
