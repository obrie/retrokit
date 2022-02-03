#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

alias install=configure
alias uninstall=restore

systems_override_config="$HOME/.emulationstation/es_systems.cfg"

configure() {
  stop_emulationstation
  __configure_systems
  __configure_platforms
}

__configure_systems() {
  local systems_default_config="/etc/emulationstation/es_systems.cfg"
  local systems_staging_config="$tmp_ephemeral_dir/es_systems.cfg"
  backup_file "$systems_override_config"

  printf '<?xml version="1.0"?>\n<systemList>\n' > "$systems_staging_config"

  # Add configured systems
  while read system; do
    xmlstarlet sel -t -c "/systemList/system[name='$system']" "$systems_default_config" >> "$systems_staging_config" || true
    printf '\n' >> "$systems_staging_config"
  done < <(setting '.systems + [select(.retropie.show_menu) | "retropie"] | .[]')

  printf '</systemList>\n' >> "$systems_staging_config"

  # Promote this to the real config
  mv "$systems_staging_config" "$systems_override_config"
}

__configure_platforms() {
  while read system; do
    # Override platform
    local platform=$(crudini --get "$config_dir/emulationstation/platforms.cfg" '' "${system}_platform" 2>/dev/null || echo '')
    if [ -n "$platform" ]; then
      platform=${platform//\"/}
      xmlstarlet ed -L -u "systemList/system[name=\"$system\"]/platform" -v "$platform" "$systems_override_config"
    fi

    # Override theme
    local theme=$(crudini --get "$config_dir/emulationstation/platforms.cfg" '' "${system}_theme" 2>/dev/null || echo '')
    if [ -n "$theme" ]; then
      theme=${theme//\"/}
      xmlstarlet ed -L -u "systemList/system[name=\"$system\"]/theme" -v "$theme" "$systems_override_config"
    fi
  done < <(setting '.systems[]')
}

restore() {
  restore_file "$systems_override_config" delete_src=true
}

"${@}"
