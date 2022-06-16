#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='ssh'
setup_module_desc='Enables SSH authentication'

configure() {
  __configure_service
  __configure_authentication
  __configure_authorized_keys
  __configure_private_keys
  __configure_known_hosts
}

__configure_service() {
  sudo systemctl enable ssh
  sudo systemctl start ssh
}

__configure_authentication() {
  if [ -n "$LOGIN_PASSWORD" ] && [ -n "$LOGIN_USER" ]; then
    echo "$LOGIN_USER:$LOGIN_PASSWORD" | sudo chpasswd
  fi
}

__configure_authorized_keys() {
  file_cp '{config_dir}/ssh/authorized_keys' "$HOME/.ssh/authorized_keys"
}

__configure_private_keys() {
  while read source_key_path; do
    local keyname=$(basename "$source_key_path")
    local target_key_path="$HOME/.ssh/$keyname"

    file_cp "$source_key_path" "$target_key_path"
    chmod 600 "$target_key_path"
  done < <(each_path '{config_dir}/ssh' find '{}' -name 'id_rsa*')

  file_cp '{config_dir}/ssh/config' "$HOME/.ssh/config"
  chmod 600 "$HOME/.ssh/config"
}

__configure_known_hosts() {
  file_cp '{config_dir}/ssh/known_hosts' "$HOME/.ssh/known_hosts-retrokit"
}

restore() {
  restore_file "$HOME/.ssh/known_hosts" delete_src=true
  restore_file "$HOME/.ssh/authorized_keys" delete_src=true
  restore_file "$HOME/.ssh/config" delete_src=true

  while read key_path; do
    restore_file "$key_path" delete_src=true
  done < <(ls "$HOME/.ssh/id_rsa-"* | grep -Ev 'rk-src')

  sudo systemctl stop ssh
  sudo systemctl disable ssh
}

setup "${@}"
