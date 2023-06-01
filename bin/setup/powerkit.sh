#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='powerkit'
setup_module_desc='Hardware safe shutdown scripts'

install_dir="$retropie_dir/supplementary/powerkit"

depends() {
  "$lib_dir/devicekit/setup.sh" depends
  "$lib_dir/powerkit/setup.sh" depends

  dir_rsync '{lib_dir}/devicekit/' "$retropie_dir/supplementary/devicekit/" as_sudo=true
}

build() {
  file_cp '{config_dir}/powerkit/powerkit.service' /etc/systemd/system/powerkit.service as_sudo=true backup=false

  # Copy powerkit to the retropie install path so that nothing depends
  # on retrokit being on the system
  dir_rsync '{lib_dir}/powerkit/' "$install_dir/" as_sudo=true
}

configure() {
  ini_merge '{config_dir}/powerkit/powerkit.cfg' "$retropie_configs_dir/all/powerkit.cfg" backup=false overwrite=true
  sudo systemctl enable powerkit.service

  # Restart
  sudo systemctl restart powerkit

  __configure_emulationstation
}

# Install emulationstation hooks
__configure_emulationstation() {
  __restore_emulationstation

  while read hook_file; do
    local hook=$(basename "$hook_file" .sh)
    local target_dir="$home/.emulationstation/scripts/$hook"
    mkdir -pv "$target_dir"
    ln -fsv "$hook_file" "$target_dir/powerkit.sh"
  done < <(ls "$install_dir/emulationstation-scripts/"*.sh)

  xmlstarlet ed --inplace -s "/inputList/inputAction" -t elem -n 'command' -v "$home/.emulationstation/scripts/controls-onfinish/powerkit.sh" "$home/.emulationstation/es_input.cfg"
}

restore() {
  sudo systemctl stop powerkit.service || true
  sudo systemctl disable powerkit.service || true

  __restore_emulationstation
}

__restore_emulationstation() {
  rm -fv "$home/.emulationstation/scripts"/*/powerkit.sh
  xmlstarlet ed --inplace -d "/inputList/inputAction/command[contains(., \"powerkit\")]" "$home/.emulationstation/es_input.cfg"
}

remove() {
  sudo rm -rfv \
    "$install_dir" \
    "$retropie_configs_dir/all/powerkit.cfg" \
    /etc/systemd/system/powerkit.service

  [ -z $(command -v pip3) ] || sudo pip3 uninstall -y gpiozero
}

setup "${@}"
