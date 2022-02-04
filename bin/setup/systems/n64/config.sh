#!/bin/bash

system='n64'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

configure() {
  ini_merge "$system_config_dir/GLideN64.custom.ini" "$retropie_system_config_dir/GLideN64.custom.ini"
  ini_merge "$system_config_dir/mupen64plus.cfg" "$retropie_system_config_dir/mupen64plus.cfg"

  local source_inputs_file="$system_config_dir/InputAutoCfg.ini"
  local target_inputs_file="$retropie_system_config_dir/InputAutoCfg.ini"
  backup_file "$target_inputs_file"

  echo "Merging ini $source_inputs_file to $target_inputs_file"
  while IFS= read -r section_name; do
    if grep -q "\[$section_name\]" "$target_inputs_file"; then
      # The section already exists -- we can just do a direct merge
      crudini --merge --inplace "$target_inputs_file" "$section_name" < "$system_config_dir/InputAutoCfg.ini"
    else
      # The section doesn't yet exist.  We need to add START / END comments
      # to work with retropie's autoconfig
      printf "\n\n; ${section_name}_START" >> "$target_inputs_file"
      crudini --merge --inplace "$target_inputs_file" "$section_name" < "$system_config_dir/InputAutoCfg.ini"
      printf "\n; ${section_name}_END" >> "$target_inputs_file"
    fi
  done < <(crudini --get "$source_inputs_file")
}

restore() {
  # Explicitly don't revert InputAutoCfg.ini in case new controllers have been added
  restore_file "$retropie_system_config_dir/mupen64plus.cfg" delete_src=true
  restore_file "$retropie_system_config_dir/GLideN64.custom.ini" delete_src=true
}

"${@}"
