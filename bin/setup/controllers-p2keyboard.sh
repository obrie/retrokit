#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='retropie-p2keyboard'
setup_module_desc='RetroPie menu for multiplayer keyboard configuration'

configure() {
  configure_retropie_package 'p2keyboard'
}

remove() {
  uninstall_retropie_package 'p2keyboard'
}

setup "${@}"
