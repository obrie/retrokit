#!/bin/bash

system="${2:-arcade}"
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

setup_module_id='systems/arcade/advmame'
setup_module_desc='AdvMAME configuration settings'

config_file="$retropie_configs_dir/mame-advmame/advmame.rc"

configure() {
  __configure_dirs
  __configure_advmame
}

__configure_dirs() {
  # Move advmame config directory in arcade system in order to avoid artwork zip
  # files from being scraped since there's no way to tell Skyscraper to ignore certain
  # directories
  if [ -d "$roms_dir/arcade/advmame" ]; then
    rm -rfv "$roms_dir/arcade/.advmame-config"
    mv -v "$roms_dir/arcade/advmame" "$roms_dir/arcade/.advmame-config"
  fi
}

__configure_advmame() {
  backup_file "$config_file"
  __restore_config

  # Add overrides
  ini_no_delimiter_merge '{system_config_dir}/advmame.rc' "$config_file"

  # Add possible rom paths
  sed -i '/dir_rom /d' "$config_file"
  echo "dir_rom $(system_setting '[.roms.dirs[] | .path] | join(":")' | envsubst)" >> "$config_file"

  # Make the config readable
  sort -o "$config_file" "$config_file"
}

restore() {
  # Restore advmame config, keeping the input_maps in the process
  __restore_config delete_src=true

  # Restore the advmame config directory
  if [ -d "$roms_dir/arcade/.advmame-config" ]; then
    rm -rfv "$roms_dir/arcade/advmame"
    mv -v "$roms_dir/arcade/.advmame-config" "$roms_dir/arcade/advmame"
  fi
}

__restore_config() {
  restore_partial_ini "$config_file" '^input_map' remove_source_matches=true "${@}"
}

setup "${@}"
