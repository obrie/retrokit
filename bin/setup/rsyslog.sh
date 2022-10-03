#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='rsyslog'
setup_module_desc='RSyslog configurations'

configure() {
  file_cp '{config_dir}/rsyslog/retrokit.conf' '/etc/rsyslog.d/retrokit.conf' as_sudo=true backup=false
}

restore() {
  sudo rm -fv /etc/rsyslog.d/retrokit.conf
}

setup "${@}"
