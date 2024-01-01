#!/bin/bash

system='c64'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../system-common.sh"

setup_module_id='admin/c64-joyports'
setup_module_desc='Generates joyport tags for c64 data files (local development purposes only)'

# .cfg settings to allow overrides for
retroarch_config_allowlist=(
  audio_volume
  fastforward_ratio
  input_max_users
)
retroarch_config_allowlist_pattern=$(printf '%s|' "${retroarch_config_allowlist[@]}")
retroarch_config_allowlist_pattern=${retroarch_config_allowlist_pattern%|}

# .cfg settings to ignore overrides for
retroarch_config_ignorelist=(
  input_disk_next
  input_disk_prev
  input_duty_cycle
  input_overlay
  input_player1_turbo
  input_poll_type_behavior
  input_turbo_period
  video_font_enable
)
retroarch_config_ignorelist_pattern=$(printf '%s|' "${retroarch_config_ignorelist[@]}")
retroarch_config_ignorelist_pattern=${retroarch_config_ignorelist_pattern%|}

# VICE core option defaults
declare -A retroarch_core_option_defaults
retroarch_core_option_defaults=(
  [vice_analogmouse_deadzone]='20'
  [vice_analogmouse]='left'
  [vice_analogmouse_speed]='1.0'
  [vice_aspect_ratio]='auto'
  [vice_audio_leak_emulation]='disabled'
  [vice_audio_options_display]='disabled'
  [vice_autoloadwarp]='disabled'
  [vice_autostart]='enabled'
  [vice_c64_model]='C64 PAL'
  [vice_cartridge]='none'
  [vice_datasette_hotkeys]='disabled'
  [vice_datasette_sound]='disabled'
  [vice_dpadmouse_speed]='6'
  [vice_drive_sound_emulation]='20%'
  [vice_drive_true_emulation]='enabled'
  [vice_easyflash_write_protection]='disabled'
  [vice_external_palette]='default'
  [vice_floppy_write_protection]='disabled'
  [vice_gfx_colors]='16bit'
  [vice_jiffydos]='disabled'
  [vice_joyport]='2'
  [vice_joyport_pointer_color]='blue'
  [vice_joyport_type]='1'
  [vice_keyboard_keymap]='positional'
  [vice_keyrah_keypad_mappings]='disabled'
  [vice_manual_crop_bottom]='37'
  [vice_manual_crop_left]='32'
  [vice_manual_crop_right]='32'
  [vice_manual_crop_top]='35'
  [vice_mapper_a]='---'
  [vice_mapper_aspect_ratio_toggle]='---'
  [vice_mapper_b]='---'
  [vice_mapper_datasette_forward]='RETROK_RIGHT'
  [vice_mapper_datasette_reset]='---'
  [vice_mapper_datasette_rewind]='RETROK_LEFT'
  [vice_mapper_datasette_start]='RETROK_UP'
  [vice_mapper_datasette_stop]='RETROK_DOWN'
  [vice_mapper_datasette_toggle_hotkeys]='---'
  [vice_mapper_down]='---'
  [vice_mapper_joyport_switch]='RETROK_RCTRL'
  [vice_mapper_l]='---'
  [vice_mapper_l2]='RETROK_ESCAPE'
  [vice_mapper_l3]='---'
  [vice_mapper_ld]='---'
  [vice_mapper_left]='---'
  [vice_mapper_ll]='---'
  [vice_mapper_lr]='---'
  [vice_mapper_lu]='---'
  [vice_mapper_r]='---'
  [vice_mapper_r2]='RETROK_RETURN'
  [vice_mapper_r3]='---'
  [vice_mapper_rd]='---'
  [vice_mapper_reset]='RETROK_END'
  [vice_mapper_right]='---'
  [vice_mapper_rl]='---'
  [vice_mapper_rr]='---'
  [vice_mapper_ru]='---'
  [vice_mapper_save_disk_toggle]='---'
  [vice_mapper_select]='TOGGLE_VKBD'
  [vice_mapper_start]='---'
  [vice_mapper_statusbar]='RETROK_F12'
  [vice_mapper_turbo_fire_toggle]='---'
  [vice_mapper_up]='---'
  [vice_mapper_vkbd]='---'
  [vice_mapper_warp_mode]='---'
  [vice_mapper_x]='RETROK_SPACE'
  [vice_mapper_y]='---'
  [vice_mapping_options_display]='enabled'
  [vice_mouse_speed]='100'
  [vice_physical_keyboard_pass_through]='disabled'
  [vice_ram_expansion_unit]='none'
  [vice_read_vicerc]='enabled'
  [vice_reset]='autostart'
  [vice_resid_8580filterbias]='1500'
  [vice_resid_filterbias]='500'
  [vice_resid_gain]='97'
  [vice_resid_passband]='90'
  [vice_resid_sampling]='fast'
  [vice_retropad_options]='disabled'
  [vice_sfx_sound_expander]='disabled'
  [vice_sid_engine]='ReSID'
  [vice_sid_extra]='disabled'
  # We use "6581" instead of "default" since that's the actual value we'd default to
  [vice_sid_model]='6581'
  [vice_sound_sample_rate]='48000'
  [vice_statusbar]='bottom'
  [vice_turbo_fire_button]='B'
  [vice_turbo_fire]='disabled'
  [vice_turbo_pulse]='6'
  [vice_userport_joytype]='disabled'
  [vice_vicii_color_brightness]='1000'
  [vice_vicii_color_contrast]='1000'
  [vice_vicii_color_gamma]='2800'
  [vice_vicii_color_saturation]='1000'
  [vice_vicii_color_tint]='1000'
  [vice_vicii_filter]='disabled'
  [vice_vicii_filter_oddline_offset]='1000'
  [vice_vicii_filter_oddline_phase]='1000'
  [vice_video_options_display]='disabled'
  [vice_virtual_device_traps]='disabled'
  [vice_vkbd_theme]='auto'
  [vice_vkbd_transparency]='25%'
  [vice_warp_boost]='disabled'
  [vice_work_disk]='disabled'
)
retroarch_core_option_ignorelist=(
  vice_border

  # Deprecated
  vice_autostart_warp
  vice_C128Model
  vice_Controller
  vice_Drive8Type
  vice_drive_sound_volume
  vice_mapper_bcrop_horiz_cycle
  vice_mapper_bcrop_horiz_mode_cycle
  vice_mapper_bcrop_vert_cycle
  vice_mapper_bcrop_vert_mode_cycle
  vice_mapper_bcrop_zoom_cycle
  vice_mapper_bcrop_zoom_toggle
  vice_mapper_zoom_mode_cycle
  vice_mapper_zoom_mode_toggle
  vice_RetroJoy
  vice_theme
  vice_vkbd_alpha
  vice_zoom_mode
  vice_zoom_mode_crop

  # Deprecated (old usage)
  vice_drive_sound_emulation

  # Ignore (performance reasons)
  vice_resid_sampling
  vice_sid_engine
  vice_warp_boost

  # Ignore (significantly slower loading when these are overridden)
  vice_drive_true_emulation
  vice_autoloadwarp

  # Ignore (defaults changed between VICE versions and there's no reason for game-specific overrides)
  vice_analogmouse_deadzone
  vice_turbo_pulse
  vice_vicii_color_gamma

  # Ignore (globals that have no game-specific overrides and are different from retrokit defaults)
  vice_mapper_joyport_switch
  vice_mapper_l2
  vice_mapper_select

  # Ignore (Inconsistent and not relevant)
  vice_autostart
  vice_mapping_options_display
  vice_statusbar
  vice_virtual_device_traps
  vice_vkbd_theme

  # Ignored values
  vice_userport_joytype\ =\ "None"
)
retroarch_core_option_ignorelist_pattern=$(printf '%s|' "${retroarch_core_option_ignorelist[@]}")
retroarch_core_option_ignorelist_pattern=${retroarch_core_option_ignorelist_pattern%|}

configure() {
  if [ -z "$C64_DREAMS_HOME" ]; then
    echo "C64_DREAMS_HOME must be set"
    return 1
  fi

  __load_defaults

  while IFS=$'\t' read -r group c64_dreams_name; do
    local config_path="$C64_DREAMS_HOME/C64 Dreams/Retroarch/config/VICE x64/$c64_dreams_name.cfg"
    local core_options_path="$C64_DREAMS_HOME/C64 Dreams/Retroarch/config/VICE x64/$c64_dreams_name.opt"

    if [ -f "$config_path" ]; then
      __configure_retroarch_config "$group" "$config_path"
    fi

    if [ -f "$core_options_path" ]; then
      __configure_retroarch_core_options "$group" "$core_options_path"
    fi
  done < <(romkit_cache_list | jq -r 'select(.tags | index("C64 Dreams")) | [.group .name, .custom."c64dreams-name" // .group .name] | @tsv' | uniq)
}

# Loads defaults from retrokit's overrides (higher priority over what's
# defined in this file)
__load_defaults() {
  while read option value; do
    retroarch_core_option_defaults[$option]=$value
  done < <(__list_ini_settings "$system_config_dir/retroarch-core-options.cfg")
}

# Configures the retroarch configuration for a specific game
__configure_retroarch_config() {
  local group=$1
  local source_path=$2
  local target_path="$system_config_dir/retroarch/$group.cfg"

  __restore_ini "$target_path"

  local overrides=()
  while read config_name value; do
    if [[ "$config_name" =~ $retroarch_config_ignorelist_pattern ]]; then
      # Ignore
      continue
    elif [[ "$config_name = \"$value\"" =~ $retroarch_config_allowlist_pattern ]]; then
      overrides+=("$config_name = \"$value\"")
    else
      echo "Unknown config: $config_name"
    fi
  done < <(__list_ini_settings "$source_path")

  if [ ${#overrides[@]} -gt 0 ]; then
    local overrides_content=$(printf '%s\n' "${overrides[@]}")
    __prepend_to_ini "$overrides_content" "$target_path"
  fi
}

# Configures the retroarch core options for a specific game
__configure_retroarch_core_options() {
  local group=$1
  local source_path=$2
  local target_path="$system_config_dir/retroarch/$group.opt"

  __restore_ini "$target_path"

  local overrides=()
  while read option value; do
    local default_value=${retroarch_core_option_defaults[$option]}

    if [[ "$option = \"$value\"" =~ $retroarch_core_option_ignorelist_pattern ]]; then
      # Ignore
      continue
    elif [ -n "$default_value" ]; then
      if [ "$value" != "$default_value" ]; then
        # Value isn't default -- add an override
        overrides+=("$option = \"$value\"")
      fi
    else
      echo "Unknown option: $option"
    fi
  done < <(__list_ini_settings "$source_path")

  if [ ${#overrides[@]} -gt 0 ]; then
    local overrides_content=$(printf '%s\n' "${overrides[@]}")
    __prepend_to_ini "$overrides_content" "$target_path"
  fi
}

# Restores the file at the given path
__restore_ini() {
  local path=$1

  if [ -f "$path" ] && grep -Fq '# Overrides' "$path"; then
    local overrides_path=$(mktemp -p "$tmp_ephemeral_dir")
    sed -n '/# Overrides/,$p' "$path" > "$overrides_path"
    mv "$overrides_path" "$path"
  else
    rm -fv "$path"
  fi
}

# Preprends content to the given path.  If the path doesn't exist, it'll be created.
__prepend_to_ini() {
  local content=$1
  local path=$2

  if [ -f "$path" ]; then
    local staging_path=$(mktemp -p "$tmp_ephemeral_dir")
    echo "$content" | cat - "$path" > "$staging_path"
    mv "$staging_path" "$path"
  else
    echo "$content" > "$path"
  fi
}

# Provides a high-performance lookup of ini configuration options.  We use this instead
# of crudini because crudini would be too slow.
__list_ini_settings() {
  cat "$1" | grep '^[^#;].*=.*' | sed -e 's/\s*=\s*/\t/g' -e 's/\t"\(.*\)".*$/\t\1/g' -e 's/\r//g' -e '$a\' | grep .
}

setup "${@}"
