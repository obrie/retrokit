#!/bin/bash

set -ex

system="${2:-arcade}"
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

install() {
  local config_path='/opt/retropie/configs/mame-advmame/advmame.rc'
  backup_and_restore "$config_path"

  while IFS="$tab" read -r name value; do
    if [ -z "$name" ]; then
      continue
    fi

    local escaped_name=$(printf '%s\n' "$name" | sed 's/[.[\*^$]/\\&/g')

    sed -i "/$escaped_name /d" "$config_path"
    echo "$name $value" >> "$config_path"
  done < <(cat "$system_config_dir/advmame.rc" | sed -rn 's/^([^ ]+) (.*)$/\1\t\2/p')

  sort -o "$config_path" "$config_path"

  # Move advmame config directory in arcade system in order to avoid artwork zip
  # files from being scraped since there's no way to tell Skyscraper to ignore certain
  # directories
  if [ -d "$HOME/RetroPie/roms/arcade/advmame" ]; then
    mv "$HOME/RetroPie/roms/arcade/advmame" "$HOME/RetroPie/roms/arcade/.advmame-config"
  fi
}

uninstall() {
  echo 'No uninstall for arcade'
}

if [ "$system" == 'arcade' ]; then
  "${@}"
fi
