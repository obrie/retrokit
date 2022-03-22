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
  # Note that we can't use crudini for dtoverlay additions because it doesn't
  # support repeating the same key multiple times in the same section

  ini_merge '{config_dir}/boot/config.txt' '/boot/config.txt' space_around_delimiters=false as_sudo=true

  __configure_bios_wifi
  __configure_bios_ir
  __configure_bios_case
}

# Wifi configuration
__configure_bios_wifi() {
  if [ "$(setting '.hardware.wifi.enabled')" == 'false' ]; then
    echo 'dtoverlay=disable-wifi' | sudo tee -a /boot/config.txt
  fi
}

# IR configuration
__configure_bios_ir() {
  local ir_gpio_pin=$(setting '.hardware.ir.gpio_pin')
  local ir_keymap_path=$(setting '.hardware.ir.keymap')
  if [ -n "$ir_gpio_pin" ] || [ -n "$ir_keymap_path" ]; then
    sudo apt install -y ir-keytable
    local ir_keymap_filename=$(basename "$ir_keymap_path")
    local rc_map_name=$(grep "$ir_keymap_filename" '/etc/rc_maps.cfg' | tr $'\t' ' ' | cut -d' ' -f 2)

    echo "dtoverlay=gpio-ir,gpio_pin=$ir_gpio_pin,rc-map-name=$rc_map_name" | sudo tee -a /boot/config.txt
  fi
}

# Add case-specific boot options.  We do this here instead of the case setup
# in order to avoid multiple scripts modifying the /boot/config.txt file.
__configure_bios_case() {
  local case=$(setting '.hardware.case.model')
  each_path "{config_dir}/boot/config/$case.txt" cat '{}' | sudo tee -a /boot/config.txt >/dev/null
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
