#!/bin/bash

set -e
[ "$DEBUG" == 'true' ] && set -x

setup_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
export app_dir=$(cd "$setup_dir/.." && pwd)
export bin_dir="$app_dir/bin"
export ext_dir="$app_dir/ext"
export lib_dir="$app_dir/lib"

# RetroPie paths
export retropie_dir="/opt/retropie"
export retropie_configs_dir="$retropie_dir/configs"
export retropie_emulators_dir="$retropie_dir/emulators"

export retropie_data_dir="$HOME/RetroPie"
export bios_dir="$retropie_data_dir/BIOS"
export roms_dir="$retropie_data_dir/roms"

export retropie_setup_dir="$HOME/RetroPie-Setup"

# Import helper functions
source "$bin_dir/helpers/configs.sh"
source "$bin_dir/helpers/downloads.sh"
source "$bin_dir/helpers/emulationstation.sh"
source "$bin_dir/helpers/hooks.sh"
source "$bin_dir/helpers/logging.sh"
source "$bin_dir/helpers/profiles.sh"
source "$bin_dir/helpers/retropie_packages.sh"
source "$bin_dir/helpers/versions.sh"

# Variables to be consumed externally
export RETROKIT_HOME=$app_dir

# Ensures that any core, required dependencies have been installed
# 
# These are required for execution of setup before any setupmodule
# has been installed.
__check_core_depends() {
  if [ ! `command -v jq` ]; then
    print_heading 'Installing retrokit common dependencies'
    sudo apt-get install -y jq
  fi
}

# Sets up dependencies and common variables used by
# other scripts
__setup_env() {
  if [ -z "$RETROKIT_HAS_EXPORTS" ]; then
    __check_core_depends

    # Define package directories
    export cache_dir="$app_dir/cache"
    export config_dir="$app_dir/config"
    export data_dir="$app_dir/data"
    export docs_dir="$app_dir/docs"
    export profiles_dir="$app_dir/profiles"
    export tmp_dir=${TMPDIR:-$app_dir/tmp}
    export common_ephemeral_dir=$(mktemp -d -p "$tmp_dir")
    export tmp_ephemeral_dir=$(mktemp -d -p "$common_ephemeral_dir")
    trap 'rm -rf -- "$common_ephemeral_dir"' EXIT

    # Read environment variable overrides.
    # 
    # We always load the root .env first since that may contain the `PROFILES` env override.
    if [ -f "$app_dir/.env" ]; then
      source "$app_dir/.env"
    fi
    init_profiles
    while read env_file; do
      source "$env_file"
    done < <(each_path '{app_dir}/.env')

    # Define settings file
    export settings_file=$(mktemp -p "$common_ephemeral_dir")
    json_merge '{config_dir}/settings.json' "$settings_file" backup=false >/dev/null

    # Mark exports as being complete so that subsequent setup module executions
    # don't need to re-evaluate all of this
    export RETROKIT_HAS_EXPORTS=true
  else
    # Remove any existing files in the ephemeral directory since this can get reused
    # across multiple scripts
    rm -rf "$tmp_ephemeral_dir/"*

    init_profiles
  fi
}

##############
# Settings
##############

# Looks up a setting in the global settings file
setting() {
  jq -r "$1 | values" "$settings_file"
}

list_setupmodules() {
  setting '.setup | .default + (to_entries[] | select(.key | startswith("add")) | .value) - (to_entries[] | select(.key | startswith("remove")) | .value) | .[]' | awk '!x[$0]++'
}

# Is the given setupmodule is enabled?
has_setupmodule() {
  list_setupmodules | grep -q "^$1\$"
}

# Generates a settings file based on current configuration settings:
# * Merges common settings with system overrides
# * Merges data paths from profiles
generate_system_settings_file() {
  local system=$1
  local merge_metadata=${2:-true}

  # Build settings file
  local system_settings_file=$(mktemp -p "$tmp_ephemeral_dir")
  json_merge '{config_dir}/systems/settings-common.json' "$system_settings_file" backup=false >/dev/null
  json_merge "{config_dir}/systems/$system/settings.json" "$system_settings_file" backup=false >/dev/null

  # Merge data file
  if [ "$merge_metadata" == 'true' ]; then
    system_data_merged_file=$(mktemp -p "$tmp_ephemeral_dir")
    system_data_file=$(jq -r '.metadata .path // empty' "$system_settings_file")

    if [ -n "$system_data_file" ]; then
      system_data_name=$(basename "$system_data_file")
      json_merge "{data_dir}/$system_data_name" "$system_data_merged_file" backup=false envsubst=false >/dev/null
      json_edit "$system_settings_file" '.metadata .path' "$system_data_merged_file"
    fi
  fi

  echo "$system_settings_file"
}

##############
# Setup stubs
##############

setup() {
  local action=$1

  if ! check_prereqs "${@}"; then
    echo 'Prerequisites not met. Skipping.'
    return
  fi

  # Confirmation dialog
  if [[ "$action" =~ ^uninstall|remove$ ]] && [ "$CONFIRM" != 'false' ]; then
    read -p "Are you sure? (y/n) " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo 'Aborted.'
      exit 1
    fi
  fi

  "${@}"
}

# Checks that the necessary prerequisites are met to run this module
check_prereqs() {
  return
}

# Installs the setupmodule
install() {
  depends
  build
  configure
  clean
}

# Installs required system dependencies
depends() {
  return
}

# Creates any required artifacts and installs them to the filesystem
build() {
  return
}

# Configures the setupmodule
configure() {
  return
}

# Cleans up any unneeded files left behind
clean() {
  return
}

# Forces the setupmodule to be updated regardless of what's already been
# downloaded / installed
update() {
  FORCE_UPDATE=true
  install
}

# Uninstalls everything installed by the setupmodule, restoring configurations
# back to their original form
uninstall() {
  restore
  remove
}

# Restores the configurations modified by the setupmodule
restore() {
  return
}

# Removes any non-configuration files installed to the system
remove() {
  return
}

# Uninstalls everything and then installs it again
reinstall() {
  uninstall
  install
}

# Finds files that can be deleted from the filesystem.  This will only
# echo the `rm` commands -- you must run them.
vacuum() {
  return
}

# Restores the current setup module before RetroPie packages are reconfigured
before_retropie_reconfigure() {
  if [ "$setup_module_reconfigure_after_update" == 'true' ]; then
    restore
  fi
}

# Re-configures the current setup module after RetroPie packages were reconfigured
after_retropie_reconfigure() {
  if [ "$setup_module_reconfigure_after_update" == 'true' ]; then
    configure
  fi
}

__setup_env
