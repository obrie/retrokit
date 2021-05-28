#!/bin/bash

set -ex

system="${2:-arcade}"
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

config_path='/opt/retropie/configs/mame-advmame/advmame.rc'

restore_config() {
  if has_backup "$config_path"; then
    if [ -f "$config_path" ]; then
      # Keep track of the input_maps since we don't want to lose those
      grep -E '^input_map' "$config_path" > "$system_tmp_dir/inputs.rc"

      # Restore and remove any input_maps from the original file
      restore "$config_path" "${@}"
      sed -i '/^input_map/d' "$config_path"

      # Merge the input_maps back in
      crudini --inplace --merge "$config_path" < "$system_tmp_dir/inputs.rc"
      rm "$system_tmp_dir/inputs.rc"
    else
      restore "$config_path" "${@}"
    fi
  fi
}

install() {
  backup "$config_path"
  restore_config "$config_path"

  # Add overrides.  This is a custom non-ini format, so we need to do it manually.
  while IFS="$tab" read -r name value; do
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
  done < <(cat "$system_config_dir/advmame.rc" | sed -rn 's/^([^ ]+) (.*)$/\1\t\2/p')

  # Add possible rom paths
  sed -i '/dir_rom /d' "$config_path"
  echo "dir_rom $(system_setting '[.roms.dirs[] | .path] | join(":")' | envsubst)" >> "$config_path"

  # Make the config readable
  sort -o "$config_path" "$config_path"

  # Move advmame config directory in arcade system in order to avoid artwork zip
  # files from being scraped since there's no way to tell Skyscraper to ignore certain
  # directories
  if [ -d "$HOME/RetroPie/roms/arcade/advmame" ]; then
    rm -rf "$HOME/RetroPie/roms/arcade/.advmame-config"
    mv "$HOME/RetroPie/roms/arcade/advmame" "$HOME/RetroPie/roms/arcade/.advmame-config"
  fi
}

uninstall() {
  # Restore the advmame config directory
  if [ -d "$HOME/RetroPie/roms/arcade/.advmame-config" ]; then
    rm -rf "$HOME/RetroPie/roms/arcade/advmame"
    mv "$HOME/RetroPie/roms/arcade/.advmame-config" "$HOME/RetroPie/roms/arcade/advmame"
  fi

  # Restore advmame.rc, keeping the input_maps in the process
  restore_config "$config_path" delete_src=true
}

if [ "$system" == 'arcade' ]; then
  "${@}"
fi
