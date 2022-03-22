#!/bin/bash

system="${2:-arcade}"
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

setup_module_id='systems/arcade/advmame'
setup_module_desc='MAME 0.230 tools, like chdman, not available through system packages'

config_path='/opt/retropie/configs/mame-advmame/advmame-joy.rc'

configure() {
  __configure_dirs
  __configure_advmame
}

__configure_dirs() {
  # Move advmame config directory in arcade system in order to avoid artwork zip
  # files from being scraped since there's no way to tell Skyscraper to ignore certain
  # directories
  if [ -d "$HOME/RetroPie/roms/arcade/advmame" ]; then
    rm -rfv "$HOME/RetroPie/roms/arcade/.advmame-config"
    mv -v "$HOME/RetroPie/roms/arcade/advmame" "$HOME/RetroPie/roms/arcade/.advmame-config"
  fi
}

__configure_advmame() {
  backup_file "$config_path"
  __restore_config

  # Add overrides.  This is a custom non-ini format, so we need to do it manually.
  each_path "{system_config_dir}/advmame.rc" __configure_advmame_ini '{}'

  # Add possible rom paths
  sed -i '/dir_rom /d' "$config_path"
  echo "dir_rom $(system_setting '[.roms.dirs[] | .path] | join(":")' | envsubst)" >> "$config_path"

  # Make the config readable
  sort -o "$config_path" "$config_path"
}

__configure_advmame_ini() {
  local source_path=$1

  echo "Merging ini $source_path to $config_path"
  while IFS=$'\t' read -r name value; do
    if [ -z "$name" ]; then
      continue
    fi

    # Escape the config name so that we can use it in sed to match and
    # replace the existing value
    local escaped_name=$(printf '%s\n' "$name" | sed -e 's/[]\/$*.^[]/\\&/g')

    # Remove the existing key.  We do this instead of a replace so we can avoid
    # having to also escape the value.
    sed -i "/$escaped_name /d" "$config_path"

    # Add it back in
    echo "$name $value" >> "$config_path"
  done < <(cat "$source_path" | sed -rn 's/^([^ ]+) (.*)$/\1\t\2/p')
}

restore() {
  # Restore advmame config, keeping the input_maps in the process
  __restore_config delete_src=true

  # Restore the advmame config directory
  if [ -d "$HOME/RetroPie/roms/arcade/.advmame-config" ]; then
    rm -rfv "$HOME/RetroPie/roms/arcade/advmame"
    mv -v "$HOME/RetroPie/roms/arcade/.advmame-config" "$HOME/RetroPie/roms/arcade/advmame"
  fi
}

__restore_config() {
  if has_backup_file "$config_path"; then
    if [ -f "$config_path" ]; then
      # Keep track of the input_maps since we don't want to lose those
      grep -E '^input_map' "$config_path" > "$system_tmp_dir/inputs.rc"

      # Restore and remove any input_maps from the original file
      restore_file "$config_path" "${@}"
      sed -i '/^input_map/d' "$config_path"

      # Merge the input_maps back in
      crudini --inplace --merge "$config_path" < "$system_tmp_dir/inputs.rc"
      rm "$system_tmp_dir/inputs.rc"
    else
      restore_file "$config_path" "${@}"
    fi
  fi
}

setup "${@}"
