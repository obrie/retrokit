#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../../common.sh"

setup_module_id='hardware/controllers/xpad'
setup_module_desc='Xbox wired controller setup and configuration'

xpad_conf_file='/etc/modprobe.d/xpad.conf'

configure() {
  backup_and_restore "$xpad_conf_file" as_sudo=true
  each_path '{config_dir}/controllers/xpad/xpad.conf' cat '{}' | sudo tee -a "$xpad_conf_file" >/dev/null
}

restore() {
  restore_file "$xpad_conf_file" as_sudo=true delete_src=true
}

setup "${@}"
