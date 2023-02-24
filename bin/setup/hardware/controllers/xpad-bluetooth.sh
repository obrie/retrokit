#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../../common.sh"

setup_module_id='hardware/controllers/xpad-bluetooth'
setup_module_desc='Xbox bluetooth controller setup and configuration'

xpadneo_conf_file='/etc/modprobe.d/99-xpadneo-bluetooth-overrides.conf'

build() {
  install_retropie_package 'supplementary' 'xpadneo-plus' 'source'
}

configure() {
  backup_and_restore "$xpadneo_conf_file" as_sudo=true
  each_path '{config_dir}/controllers/xpad/xpadneo.conf' cat '{}' | sudo tee -a "$xpadneo_conf_file" >/dev/null
}

restore() {
  restore_file "$xpadneo_conf_file" as_sudo=true delete_src=true
}

remove() {
  uninstall_retropie_package 'xpadneo-plus'
}

setup "${@}"
