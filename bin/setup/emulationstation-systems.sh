#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

install() {
  stop_emulationstation

  # Build system order
  local system_default_config=/etc/emulationstation/es_systems.cfg
  local system_override_config="$HOME/.emulationstation/es_systems.cfg"

  backup_file "$system_override_config"

  printf '<?xml version="1.0"?>\n<systemList>\n' > "$system_override_config.tmp"

  # Add configured systems
  while read system; do
    xmlstarlet sel -t -c "/systemList/system[name='$system']" "$system_default_config" >> "$system_override_config.tmp" || true
    printf '\n' >> "$system_override_config.tmp"
  done < <(setting '.systems + [select(.retropie.show_menu) | "retropie"] | .[]')

  printf '</systemList>\n' >> "$system_override_config.tmp"

  mv "$system_override_config.tmp" "$system_override_config"

  # Override platforms / themes
  while read system; do
    local platform=$(crudini --get "$config_dir/emulationstation/platforms.cfg" '' "${system}_platform" 2>/dev/null || echo '')
    if [ -n "$platform" ]; then
      platform=${platform//\"/}
      xmlstarlet ed -L -u "systemList/system[name=\"$system\"]/platform" -v "$platform" "$system_override_config"
    fi

    local theme=$(crudini --get "$config_dir/emulationstation/platforms.cfg" '' "${system}_theme" 2>/dev/null || echo '')
    if [ -n "$theme" ]; then
      theme=${theme//\"/}
      xmlstarlet ed -L -u "systemList/system[name=\"$system\"]/theme" -v "$theme" "$system_override_config"
    fi
  done < <(setting '.systems[]')
}

uninstall() {
  restore_file "$HOME/.emulationstation/es_systems.cfg" delete_src=true
}

"${@}"
