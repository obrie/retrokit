#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='retroarch'
setup_module_desc='Retroarch configuration options'

retroarch_config_file="$retropie_configs_dir/all/retroarch.cfg"
retroarch_default_overlay_config_file="$retropie_configs_dir/all/retroarch/overlay/base.cfg"
retroarch_default_overlay_image_file="$retropie_configs_dir/all/retroarch/overlay/base.png"
retroarch_default_overlay_lightgun_config_file="$retropie_configs_dir/all/retroarch/overlay/base-lightgun.cfg"
retroarch_default_overlay_lightgun_image_file="$retropie_configs_dir/all/retroarch/overlay/base-lightgun.png"

# Re-runs the `configure` action for retroarch
reconfigure_packages() {
  restore
  configure_retropie_package retroarch
  configure
}

configure() {
  __restore_config

  __configure_global_overrides
  __configure_shared_overrides
  __configure_overlays
}

__configure_global_overrides() {
  ini_merge '{config_dir}/retroarch/retroarch.cfg' "$retroarch_config_file" restore=false
}

__configure_shared_overrides() {
  while read shared_config_name; do
    ini_merge "{config_dir}/retroarch/$shared_config_name.cfg" "$retropie_configs_dir/all/$shared_config_name.cfg" backup=false
  done < <(each_path '{config_dir}/retroarch' find '{}'  -name 'retroarch-*.cfg' -not -name 'retroarch-core-options*.cfg' -exec basename {} .cfg \; | sort | uniq)
}

__configure_overlays() {
  # These are our own custom file, so no need to back up
  ini_merge '{config_dir}/retroarch/overlay.cfg' "$retroarch_default_overlay_config_file" backup=false
  file_cp '{config_dir}/retroarch/overlay.png' "$retroarch_default_overlay_image_file" backup=false

  ini_merge '{config_dir}/retroarch/overlay-lightgun.cfg' "$retroarch_default_overlay_lightgun_config_file" backup=false
  file_cp '{config_dir}/retroarch/overlay-lightgun.png' "$retroarch_default_overlay_lightgun_image_file" backup=false
}

restore() {
  rm -fv \
    "$retroarch_default_overlay_config_file" \
    "$retroarch_default_overlay_lightgun_config_file" \
    "$retroarch_default_overlay_image_file" \
    "$retroarch_default_overlay_lightgun_image_file"

  find "$retropie_configs_dir/all" -mindepth 1 -maxdepth 1 -name 'retroarch-*.cfg' -not -name 'retroarch-core-options*.cfg' -exec rm -fv '{}' +

  __restore_config delete_src=true
}

__restore_config() {
  restore_partial_ini "$retroarch_config_file" '^input_(player1|state_slot|reset|menu_toggle|load_state|save_state|exit_emulator|enable_hotkey)(?!.*(gun|mbtn))' "${@}"
}

setup "${@}"
