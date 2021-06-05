#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

install() {
  stop_emulationstation

  local es_settings_config="$HOME/.emulationstation/es_settings.cfg"
  local overrides_config="$config_dir/emulationstation/es_settings.cfg"

  backup_and_restore "$es_settings_config"

  if [ -f "$es_settings_config" ]; then
    while read -r xml; do
      # Get current ES settings
      existing_settings=$(sed -e '$a</settings>' -e 's/<?xml version="1.0"?>/<settings>/g' "$es_settings_config")

      # Read in overrides
      name=$(echo "$xml" | xmlstarlet sel -t -v '/*/@name')
      value=$(echo "$xml" | xmlstarlet sel -t -v '/*/@value')

      # Override in the file
      echo "$existing_settings" |\
        xmlstarlet edit --update "/*/*[@name=\"$name\"]/@value" --value "$value" |\
        xmlstarlet select -t -m '/*/*' -c '.' -n |\
        sed  -e '1s/^/<?xml version="1.0"?>\n/' \
        > "$es_settings_config"
    done < <(sed -e '$a</settings>' -e '1s/^/<settings>/' "$overrides_config" | xmlstarlet select -t -m '/*/*' -c '.' -n)
  else
    cp -v "$overrides_config" "$es_settings_config"
  fi
}

uninstall() {
  restore "$HOME/.emulationstation/es_settings.cfg" delete_src=true
}

"${@}"
