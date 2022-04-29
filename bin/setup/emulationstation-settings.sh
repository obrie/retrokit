#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='emulationstation-settings'
setup_module_desc='EmulationStation configuration settings'

configure() {
  stop_emulationstation
  __configure_es_settings
}

__configure_es_settings() {
  local es_settings_file="$HOME/.emulationstation/es_settings.cfg"
  backup_and_restore "$es_settings_file"

  # Add initial configuration file
  if [ ! -f "$es_settings_file" ]; then
    echo '<?xml version="1.0"?>' > "$es_settings_file"
  fi

  # Get current ES settings
  local es_settings=$(sed -e '$a</settings>' -e 's/<?xml version="1.0"?>/<settings>/g' "$es_settings_file")

  while read -r xml; do
    # Read in overrides
    local tag=$(echo "$xml" | xmlstarlet sel -t -m '/*' -v 'name()')
    local name=$(echo "$xml" | xmlstarlet sel -t -v '/*/@name')
    local value=$(echo "$xml" | xmlstarlet sel -t -v '/*/@value')

    if echo "$es_settings" | xmlstarlet select -Q -t -c "/*/*[@name=\"$name\"]"; then
      # Modify existing setting
      es_settings=$(
        echo "$es_settings" | \
          xmlstarlet edit --update "/*/*[@name=\"$name\"]/@value" --value "$value"
        )
    else
      # Add a new setting
      es_settings=$(
        echo "$es_settings" | \
          xmlstarlet edit --subnode '/settings' \
            -t elem -n "$tag" -v '' \
            --var config '$prev' \
            -i '$config' -t attr -n name -v "$name" \
            -i '$config' -t attr -n value -v "$value"
        )
    fi
  done < <(each_path '{config_dir}/emulationstation/es_settings.cfg' sed -e '$a</settings>' -e 's/<?xml version="1.0"?>/<settings>/g' '{}' | xmlstarlet select -t -m '/*/*' -c '.' -n)

  # Overwrite file with the new settings
  echo "$es_settings" | \
    xmlstarlet select -t -m '/*/*' -c '.' -n | \
    sed  -e '1s/^/<?xml version="1.0"?>\n/' \
    > "$es_settings_file"
}

restore() {
  restore_file "$HOME/.emulationstation/es_settings.cfg" delete_src=true
}

setup "${@}"
