#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../common.sh"

setup_module_id='hardware/cpu'
setup_module_desc='CPU configuration to improve performance'

configure() {
  sudo systemctl disable raspi-config
  sudo apt-get install -y cpufrequtils
  file_cp '{config_dir}/cpu/cpufrequtils' '/etc/default/cpufrequtils' as_sudo=true
}

restore() {
  restore_file '/etc/default/cpufrequtils' as_sudo=true delete_src=true
  sudo apt-get remove -y cpufrequtils
  sudo apt-get autoremove --purge -y
  sudo systemctl enable raspi-config
}

setup "${@}"
