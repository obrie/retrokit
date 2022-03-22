#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='emulationstation-settings'
setup_module_desc='EmulationStation configuration settings'

configure() {
  stop_emulationstation

  local es_settings_config="$HOME/.emulationstation/es_settings.cfg"
  backup_and_restore "$es_settings_config"

  # Add initial configuration file
  if [ ! -f "$es_settings_config" ]; then
    echo '<?xml version="1.0"?>' > "$es_settings_config"
  fi

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
  done < <(each_path '{config_dir}/emulationstation/es_settings.cfg' sed -e '$a</settings>' -e 's/<?xml version="1.0"?>/<settings>/g' '{}' | xmlstarlet select -t -m '/*/*' -c '.' -n)
}

restore() {
  restore_file "$HOME/.emulationstation/es_settings.cfg" delete_src=true
}

setup "${@}"
