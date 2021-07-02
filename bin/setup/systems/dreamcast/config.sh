#!/bin/bash

system='dreamcast'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

redream_dir="$retropie_system_config_dir/redream"
redream_config_path="$redream_dir/redream.cfg"

restore_config() {
  if has_backup "$redream_config_path"; then
    if [ -f "$redream_config_path" ]; then
      # Keep track of the profiles since we don't want to lose those
      grep -E '^profile[0-9]+' "$redream_config_path" > "$system_tmp_dir/profiles.cfg"

      restore "$redream_config_path" "${@}"

      # Merge the profiles back in
      crudini --merge --inplace "$redream_config_path" < "$system_tmp_dir/profiles.cfg"
      rm "$system_tmp_dir/profiles.cfg"
    else
      restore "$redream_config_path" "${@}"
    fi
  fi
}

install() {
  restore_config
  ini_merge "$system_config_dir/redream.cfg" "$redream_config_path" restore=false

  # Game overrides
  while read -r rom_config_path; do
    local filename=$(basename "$rom_config_path")
    file_cp "$rom_config_path" "$redream_dir/cache/$filename"
  done < <(find "$system_config_dir/redream" -name '*.cfg')
}

uninstall() {
  restore_config delete_src=true
}

"${@}"
