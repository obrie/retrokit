#!/bin/bash

set -ex

system="${2:-arcade}"
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

config_path='/opt/retropie/configs/mame-advmame/advmame.rc'

restore_config() {
  if has_backup "$config_path"; then
    # Keep track of the profiles since we don't want to lose those
    grep -E '^input_map' "$config_path" > "$system_tmp_dir/inputs.rc"

    restore "$config_path"
    sed -i '/^input_map/d' "$config_path"

    # Merge the profiles back in
    crudini --inplace --merge "$config_path" < "$system_tmp_dir/inputs.rc"
    rm "$system_tmp_dir/inputs.rc"
  fi
}

install() {
  restore_config "$config_path"
  backup "$config_path"

  while IFS="$tab" read -r name value; do
    if [ -z "$name" ]; then
      continue
    fi

    local escaped_name=$(printf '%s\n' "$name" | sed -e 's/[]\/$*.^[]/\\&/g')

    sed -i "/$escaped_name /d" "$config_path"
    echo "$name $value" >> "$config_path"
  done < <(cat "$system_config_dir/advmame.rc" | sed -rn 's/^([^ ]+) (.*)$/\1\t\2/p')

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
  restore_config "$config_path"
}

if [ "$system" == 'arcade' ]; then
  "${@}"
fi
