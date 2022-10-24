#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../../common.sh"

setup_module_id='hardware/cases/gpi2'
setup_module_desc='GPi2 management utilities'

build() {
  local patches_zip="$tmp_dir/gpi_case2_patch.zip"
  local overlay_base_path='GPi_Case2_patch_retropie/patch_files/overlays'
  download 'https://github.com/RetroFlag/GPiCase2-Script/raw/main/GPi_Case2_patch.zip' "$patches_zip"
  unzip -o "$patches_zip" "$overlay_base_path/*" -d "$tmp_ephemeral_dir/"

  # Screen overlay
  file_cp "$tmp_ephemeral_dir/$overlay_base_path/dpi24.dtbo" /boot/overlays/dpi24.dtbo as_sudo=true

  # Audio overlay
  file_cp "$tmp_ephemeral_dir/$overlay_base_path/pwm-audio-pi-zero.dtbo" /boot/overlays/pwm-audio-pi-zero.dtbo as_sudo=true
}

configure() {
  # Audio settings
  echo 'options snd_usb_audio index=0' > "$tmp_ephemeral_dir/alsa-base.conf"
  file_cp "$tmp_ephemeral_dir/alsa-base.conf" /etc/modprobe.d/alsa-base.conf as_sudo=true
}

restore() {
  restore_file /etc/modprobe.d/alsa-base.conf as_sudo=true delete_src=true
}

remove() {
  restore_file /boot/overlays/dpi24.dtbo as_sudo=true delete_src=true
  restore_file /boot/overlays/pwm-audio-pi-zero.dtbo as_sudo=true delete_src=true
}

setup "${@}"
