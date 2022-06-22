#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='network-dhcpd'
setup_module_desc='Network DHCPD configuration'

configure() {
  file_cp '{config_dir}/network/dhcpd/dhcpd.conf' '/etc/dhcpd.conf' as_sudo=true
  file_cp '{config_dir}/network/dhcpd/wait.conf' '/etc/systemd/system/dhcpcd.service.d/wait.conf' as_sudo=true
}

restore() {
  restore_file '/etc/dhcpd.conf' as_sudo=true delete_src=true
  restore_file '/etc/systemd/system/dhcpcd.service.d/wait.conf' as_sudo=true delete_src=true
}

setup "${@}"
