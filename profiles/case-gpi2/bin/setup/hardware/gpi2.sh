#!/bin/bash

. "$bin_dir/common.sh"

setup_module_id='hardware/gpi2'
setup_module_desc='GPi2 management utilities'

install_dir="$retropie_dir/supplementary/gpikit"

build() {
  __build_gpikit
  __build_overlays
  __build_port_shortcuts
}

__build_gpikit() {
  # Copy gpikit to the retropie install path so that nothing depends
  # on retrokit being on the system
  sudo mkdir -p "$install_dir"
  dir_rsync '{lib_dir}/gpikit/' "$install_dir/" as_sudo=true
}

__build_overlays() {
  local patches_zip="$tmp_dir/gpi_case2_patch.zip"
  local overlay_base_path='GPi_Case2_patch_retropie/patch_files/overlays'
  local extract_path=$(mktemp -d -p "$tmp_ephemeral_dir")
  download 'https://github.com/RetroFlag/GPiCase2-Script/raw/main/GPi_Case2_patch.zip' "$patches_zip"
  unzip -o "$patches_zip" "$overlay_base_path/*" -d "$extract_path/"

  # Screen overlay
  file_cp "$extract_path/$overlay_base_path/dpi24.dtbo" /boot/overlays/dpi24.dtbo as_sudo=true

  # Audio overlay
  file_cp "$extract_path/$overlay_base_path/pwm-audio-pi-zero.dtbo" /boot/overlays/pwm-audio-pi-zero.dtbo as_sudo=true
}

__build_port_shortcuts() {
  # Create ports
  dir_rsync '{lib_dir}/gpikit/shortcuts' "$roms_dir/ports/+GPi/"

  # Don't scrape ports files
  touch "$roms_dir/ports/+GPi/.skyscraperignore"
}

configure() {
  __configure_audio
  __configure_autostart
  __configure_runcommand
}

__configure_audio() {
  # Audio settings
  file_cp "{config_dir}/alsa/modprobe.conf" /etc/modprobe.d/alsa-base.conf as_sudo=true
  file_cp "{config_dir}/alsa/asound-mono.conf" /etc/asound-mono.conf as_sudo=true
  file_ln /etc/asound-mono.conf /etc/asound.conf as_sudo=true

  # Fix audio not playing during boot splashscreen
  backup_file "$retropie_dir/supplementary/splashscreen/asplashscreen.sh" as_sudo=true
  sudo sed -i 's/-o both/-o alsa/g' "$retropie_dir/supplementary/splashscreen/asplashscreen.sh"
}

# Install autostart script
__configure_autostart() {
  mkdir -p "$retropie_configs_dir/all/autostart.d"
  ln -fsnv "$install_dir/autostart" "$retropie_configs_dir/all/autostart.d/gpikit"
}

__configure_runcommand() {
  mkdir -p "$retropie_configs_dir/all/runcommand.d"
  ln -fsnv "$install_dir/runcommand" "$retropie_configs_dir/all/runcommand.d/gpikit"
}

restore() {
  __restore_audio
  __restore_autostart
  __restore_runcommand
}

__restore_audio() {
  restore_file /etc/asound.conf as_sudo=true delete_src=true
  restore_file /etc/asound-mono.conf as_sudo=true delete_src=true
  restore_file /etc/modprobe.d/alsa-base.conf as_sudo=true delete_src=true
  restore_file "$retropie_dir/supplementary/splashscreen/asplashscreen.sh" as_sudo=true delete_src=true
}

__restore_autostart() {
  rm -fv "$retropie_configs_dir/all/autostart.d/gpikit/"
}

__restore_runcommand() {
  rm -fv "$retropie_configs_dir/all/runcommand.d/gpikit/"
}

remove() {
  sudo rm -rfv "$install_dir"
  rm -rfv  "$roms_dir/ports/+GPi"
  restore_file /boot/overlays/dpi24.dtbo as_sudo=true delete_src=true
  restore_file /boot/overlays/pwm-audio-pi-zero.dtbo as_sudo=true delete_src=true
}

setup "${@}"
