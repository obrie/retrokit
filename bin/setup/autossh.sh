#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='autossh'
setup_module_desc='Remote SSH connection management'

depends() {
  sudo apt-get install -y autossh
}

build() {
  file_cp '{config_dir}/autossh/autossh.service' '/etc/systemd/system/autossh.service' as_sudo=true backup=false envsubst=false
  sudo mkdir -p /var/log/autossh /var/run/autossh
  sudo chown pi:pi /var/log/autossh /var/run/autossh
}

configure() {
  env_merge '{config_dir}/autossh/default.conf' '/etc/autossh/default.conf' as_sudo=true backup=false
  sudo systemctl enable autossh.service

  # Restart
  sudo systemctl restart autossh
}

restore() {
  sudo systemctl stop autossh.service || true
  sudo systemctl disable autossh.service || true
  sudo rm -fv /etc/autossh/default.conf
}

remove() {
  sudo rm -rfv \
    /etc/autossh \
    /etc/systemd/system/autossh.service \
    /var/log/autossh \
    /var/run/autossh

  sudo apt-get remove -y autossh
  sudo apt-get autoremove --purge -y
}

setup "${@}"
