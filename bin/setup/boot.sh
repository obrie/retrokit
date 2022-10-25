#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='boot'
setup_module_desc='BIOS / Kernel configuration'

configure() {
  __configure_bios
  __configure_kernel
}

__configure_bios() {
  # Note that we can't use crudini for dtoverlay/dtparam additions because it doesn't
  # support repeating the same key multiple times in the same section

  local case=$(setting '.hardware.case.model')

  # Build base config.txt without device tree settings settings (dtoverlay / dtparam)
  ini_merge '{config_dir}/boot/config.txt' "$tmp_ephemeral_dir/boot-staging.txt" space_around_delimiters=false backup=false overwrite=true
  ini_merge "{config_dir}/boot/config/$case.txt" "$tmp_ephemeral_dir/boot-staging.txt" space_around_delimiters=false backup=false
  sed -i '/^dt\(overlay\|param\)=/d' "$tmp_ephemeral_dir/boot-staging.txt"

  # Merge into /boot
  ini_merge "$tmp_ephemeral_dir/boot-staging.txt" '/boot/config.txt' space_around_delimiters=false as_sudo=true

  # Add repeating dtoverlay/dtparam configurations since crudini will just merge
  while read config_path; do
    while read section_name; do
      # Extract the specific source section that we're going to grep and where
      # matches should get inserted into the target
      local source_section_content
      local target_section_start
      if [ "$section_name" == 'DEFAULT' ]; then
        source_section_content=$(sed -n "1,/^\[/p" "$config_path")
        target_section_start=$(grep -En "^\[" /boot/config.txt | head -n 1 | cut -d':' -f1)
        target_section_start=$((target_section_start-1))
      else
        source_section_content=$(sed -n "/^\[$section_name\]/,/^\[/p" "$config_path")
        target_section_start=$(grep -En "^\[$section_name\]" /boot/config.txt | head -n 1 | cut -d':' -f1)
      fi

      # Find device tree configurations in the section
      local dt_content=$(echo "$source_section_content" | grep -E '^dt(overlay|param)=')
      if [ -z "$dt_content" ]; then
        continue
      fi

      # Write configurations to the section
      echo "$dt_content" > "$tmp_ephemeral_dir/dtcontent.txt"
      sudo sed -i "$target_section_start r $tmp_ephemeral_dir/dtcontent.txt" /boot/config.txt
    done < <(crudini --get "$config_path")
  done < <(cat <(each_path '{config_dir}/boot/config.txt') <(each_path "{config_dir}/boot/config/$case.txt"))

  # Move [all] section to end of the file in order to comply with recommendations
  # from Raspbian's documentation
  local all_section_content=$(sed '1,/\[all\]/d;/\[/,$d' /boot/config.txt)
  sudo sed -i '/^\[all\]/,/^\[/{//p;d;}' /boot/config.txt
  sudo sed -i '/\[all\]/d' /boot/config.txt
  echo -e "\n[all]\n$all_section_content" | sudo tee -a /boot/config.txt >/dev/null

  __configure_bios_ir
}

# IR configuration
__configure_bios_ir() {
  local ir_gpio_pin=$(setting '.hardware.ir.gpio_pin')
  local ir_keymap_path=$(setting '.hardware.ir.keymap')
  if [ -n "$ir_gpio_pin" ] && [ -n "$ir_keymap_path" ]; then
    sudo apt-get install -y ir-keytable
    local ir_keymap_filename=$(basename "$ir_keymap_path")
    local rc_map_name=$(grep "$ir_keymap_filename" '/etc/rc_maps.cfg' | tr $'\t' ' ' | cut -d' ' -f 2)

    # We are guaranteed that [all] is the last section
    echo "dtoverlay=gpio-ir,gpio_pin=$ir_gpio_pin,rc-map-name=$rc_map_name" | sudo tee -a /boot/config.txt
  fi
}

__configure_kernel() {
  backup_and_restore '/boot/cmdline.txt' as_sudo=true

  while IFS=$'\t' read search_option replace_option; do
    if grep -qE "$search_option" /boot/cmdline.txt; then
      sudo sed -i "s/$search_option[^ ]*/$replace_option/g" /boot/cmdline.txt
    else
      sudo sed -i "$ s/$/ $replace_option/" /boot/cmdline.txt
    fi
  done < <(each_path '{config_dir}/boot/cmdline.tsv' cat '{}')
}

restore() {
  restore_file '/boot/config.txt' as_sudo=true delete_src=true
  restore_file '/boot/cmdline.txt' as_sudo=true delete_src=true
}

setup "${@}"
