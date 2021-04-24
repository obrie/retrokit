#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

install_settings() {
  local es_settings_config="$HOME/.emulationstation/es_settings.cfg"
  local overrides_config="$config_dir/emulationstation/es_settings.cfg"

  backup_and_restore "$es_settings_config"

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
}

install_systems() {
  # Build system order
  local system_default_config=/etc/emulationstation/es_systems.cfg
  local system_override_config="$HOME/.emulationstation/es_systems.cfg"

  backup_and_restore "$system_override_config"

  printf '<?xml version="1.0"?>\n<systemList>\n' > "$system_override_config"

  # Add primary systems used by retrokit
  while read system; do
    xmlstarlet sel -t -c "/systemList/system[name='$system']" "$system_default_config" >> "$system_override_config"
    printf '\n' >> "$system_override_config"
  done < <(setting '.systems[]')

  # Add remaining systems
  system_conditions=$(jq -r '.systems[]' "$settings_file" | sed -e 's/.*/name="\0"/g' | sed ':a; N; $!ba; s/\n/ or /g')
  xmlstarlet sel -t -m "/systemList/system[not($system_conditions)]" -c "." -n "$system_default_config" >> "$system_override_config"
  printf '</systemList>\n' >> "$system_override_config"
}

install() {
  stop_emulationstation
  install_settings
  install_systems
}

uninstall() {
  restore "$HOME/.emulationstation/es_settings.cfg"
  restore "$HOME/.emulationstation/es_systems.cfg"
}

"${@}"
