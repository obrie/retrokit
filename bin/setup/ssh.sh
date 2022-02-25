#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='ssh'
setup_module_desc='Enables SSH authentication'

configure() {
  sudo systemctl enable ssh
  sudo systemctl start ssh
}

setup "${@}"
