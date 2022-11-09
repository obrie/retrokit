#!/bin/bash

. "$bin_dir/common.sh"

setup_module_id='hardware/controllers/xboxdrv'
setup_module_desc='Provides a userspace driver for advanced controller configurations'

depends() {
  sudo apt-get install -y acl
}

build() {
  install_retropie_package supplementary xboxdrv source
  __build_services
}

__build_services() {
  # Parent service
  file_cp '{config_dir}/xboxdrv/xboxdrv.service' /etc/systemd/system/xboxdrv.service as_sudo=true backup=false envsubst=false

  # Dependents
  while read service_path; do
    local filename=$(basename "$service_path")
    file_cp "$service_path" "/etc/systemd/system/xboxdrv-$filename" as_sudo=true backup=false envsubst=false
  done < <(each_path '{config_dir}/xboxdrv' find '{}' -name '*.service' | grep -Ev 'xboxdrv.service')
}

configure() {
  __configure_xboxdrv
  __configure_udev_rules
  __configure_systemd_services
}

__configure_xboxdrv() {
  while read config_path; do
    local filename=$(basename "$config_path")
    file_cp "$config_path" "/etc/xboxdrv/$filename" as_sudo=true backup=false
  done < <(each_path '{config_dir}/xboxdrv' find '{}' -name '*.xboxdrv')
}

__configure_udev_rules() {
  while read rules_path; do
    local filename=$(basename "$rules_path")
    file_cp "$rules_path" "/etc/udev/rules.d/99-xboxdrv-$filename" as_sudo=true backup=false envsubst=false
  done < <(each_path '{config_dir}/xboxdrv' find '{}' -name '*.rules')

  sudo udevadm control --reload-rules && sudo udevadm trigger
}

__configure_systemd_services() {
  sudo systemctl enable xboxdrv

  while read service_path; do
    local filename=$(basename "$service_path")
    sudo systemctl enable "xboxdrv-$filename"
  done < <(each_path '{config_dir}/xboxdrv' find '{}' -name '*.service' | grep -Ev 'xboxdrv.service')

  # Start the service
  sudo systemctl restart xboxdrv
}

restore() {
  # Remove configurations
  sudo rm -rfv \
    /etc/xboxdrv \
    /etc/udev/rules.d/99-xboxdrv*

  # Stop systemd services
  sudo systemctl stop xboxdrv || true
  sudo systemctl disable xboxdrv || true
  while read service_path; do
    local filename=$(basename "$service_path")
    sudo systemctl disable "xboxdrv-$filename"
  done < <(find /etc/systemd/system -maxdepth 1 -name 'xboxdrv-*.service' | grep -Ev 'xboxdrv.service')

  # Reload udev
  sudo udevadm control --reload-rules && sudo udevadm trigger
}

remove() {
  uninstall_retropie_package supplementary xboxdrv
  sudo apt-get remove -y acl
  sudo rm -rfv /etc/systemd/system/xboxdrv*.service
}

setup "${@}"
