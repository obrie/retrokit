#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='ssh'
setup_module_desc='Enables SSH authentication'

configure() {
  __configure_service
  __configure_authentication
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

setup "${@}"
