#!/bin/bash

. "$bin_dir/common.sh"

setup_module_id='hardware/controllers/xboxdrv'
setup_module_desc='Provides a userspace driver for advanced controller configurations'

depends() {
  sudo apt-get install -y acl
}

build() {
  install_retropie_package xboxdrv source
  __build_services
}

__build_services() {
  while read service_file; do
    local filename=$(basename "$service_file")
    file_cp "$service_file" "/etc/systemd/system/xboxdrv-$filename" as_sudo=true backup=false envsubst=false
  done < <(each_path '{config_dir}/xboxdrv' find '{}' -name '*.service')
}

configure() {
  __configure_xboxdrv
  __configure_udev_rules
}

__configure_xboxdrv() {
  while read config_file; do
    local filename=$(basename "$config_file")
    file_cp "$config_file" "/etc/xboxdrv/$filename" as_sudo=true backup=false
  done < <(each_path '{config_dir}/xboxdrv' find '{}' -name '*.xboxdrv')
}

__configure_udev_rules() {
  while read rules_file; do
    local filename=$(basename "$rules_file")
    file_cp "$rules_file" "/etc/udev/rules.d/99-xboxdrv-$filename" as_sudo=true backup=false envsubst=false
  done < <(each_path '{config_dir}/xboxdrv' find '{}' -name '*.rules')

  sudo udevadm control --reload-rules && sudo udevadm trigger
}

restore() {
  # Remove configurations
  sudo rm -rfv \
    /etc/xboxdrv \
    /etc/udev/rules.d/99-xboxdrv*

  # Reload udev
  sudo udevadm control --reload-rules && sudo udevadm trigger
}

remove() {
  uninstall_retropie_package xboxdrv
  sudo apt-get remove -y acl
  sudo rm -rfv /etc/systemd/system/xboxdrv*.service
}

setup "${@}"
