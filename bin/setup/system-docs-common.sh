#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

build_dir="$docs_dir/build"

# RetroArch hotkey actions
retroarch_actions_list=(
  menu_toggle exit_emulator reset close_content
  load_state save_state state_slot_decrease state_slot_increase
  disk_eject_toggle disk_next disk_prev
  cheat_toggle cheat_index_minus cheat_index_plus
  netplay_fade_chat_toggle netplay_game_watch netplay_host_toggle netplay_ping_toggle netplay_player_chat
  overlay_next shader_next shader_prev
  frame_advance toggle_fast_forward hold_fast_forward toggle_slowmotion hold_slowmotion rewind
  audio_mute volume_down volume_up
  pause_toggle recording_toggle movie_record_toggle streaming_toggle screenshot
  toggle_fullscreen desktop_menu_toggle osk_toggle game_focus_toggle grab_mouse_toggle runahead_toggle
  fps_toggle toggle_statistics send_debug_info
)
declare -A retroarch_actions
retroarch_actions=(
  [audio_mute]='Volume: Mute'
  [cheat_index_minus]='Cheats: Index +'
  [cheat_index_plus]='Cheats: Index -'
  [cheat_toggle]='Cheats: Toggle'
  [close_content]='Close Content'
  [desktop_menu_toggle]='Toggle Desktop'
  [disk_eject_toggle]='Disk: Toggle'
  [disk_next]='Disk: Next'
  [disk_prev]='Disk: Previous'
  [exit_emulator]='Exit'
  [fps_toggle]='Toggle FPS'
  [frame_advance]='Frame Advance'
  [game_focus_toggle]='Game Focus'
  [grab_mouse_toggle]='Grab Mouse'
  [hold_fast_forward]='Fast Forward: Hold'
  [hold_slowmotion]='Slow Motion: Hold'
  [load_state]='State: Load'
  [menu_toggle]='Menu'
  [movie_record_toggle]='Record: Movie'
  [netplay_fade_chat_toggle]='Netplay: Fade'
  [netplay_game_watch]='Netplay: Spectate'
  [netplay_host_toggle]='Netplay: Host'
  [netplay_ping_toggle]='Netplay: Ping'
  [netplay_player_chat]='Netplay: Chat'
  [osk_toggle]='Keyboard: Toggle'
  [overlay_next]='Overlay: Next'
  [pause_toggle]='Pause'
  [recording_toggle]='Record'
  [reset]='Reset'
  [rewind]='Rewind'
  [runahead_toggle]='Runahead'
  [save_state]='State: Save'
  [screenshot]='Screenshot'
  [send_debug_info]='Send Debug Info'
  [shader_next]='Shader: Next'
  [shader_prev]='Shader: Previous'
  [state_slot_decrease]='State: Slot +'
  [state_slot_increase]='State: Slot -'
  [streaming_toggle]='Stream'
  [toggle_fast_forward]='Fast Forward'
  [toggle_fullscreen]='Full Screen'
  [toggle_slowmotion]='Slow Motion'
  [toggle_statistics]='Show Stats'
  [volume_down]='Volume: Up'
  [volume_up]='Volume: Down'
)

# RetroArch keyboard controls
retroarch_keyboard_buttons_list=(
  a
  b
  x
  y
  start
  select
  left
  right
  up
  down
  l
  r
  l2
  r2
  l3
  r3
  l_x_plus
  l_x_minus
  l_y_plus
  l_y_minus
  r_x_plus
  r_x_minus
  r_y_plus
  r_y_minus
)
declare -A keyboard_keys
keyboard_keys=(
  [add]='Numpad +'
  [alt]='Left ALt'
  [backquote]='`'
  [backslash]='\\'
  [backspace]='Backspace'
  [capslock]='Caps Lock'
  [comma]=','
  [ctrl]='Left Ctrl'
  [del]='Delete'
  [divide]='Numpad '
  [down]='Down'
  [end]='End'
  [enter]='Return'
  [equals]='='
  [escape]='Escape'
  [f10]='F10'
  [f11]='F11'
  [f12]='F12'
  [f1]='F1'
  [f2]='F2'
  [f3]='F3'
  [f4]='F4'
  [f5]='F5'
  [f6]='F6'
  [f7]='F7'
  [f8]='F8'
  [f9]='F9'
  [home]='Home'
  [insert]='Insert'
  [keypad0]='Numpad 0'
  [keypad1]='Numpad 1'
  [keypad2]='Numpad 2'
  [keypad3]='Numpad 3'
  [keypad4]='Numpad 4'
  [keypad5]='Numpad 5'
  [keypad6]='Numpad 6'
  [keypad7]='Numpad 7'
  [keypad8]='Numpad 8'
  [keypad9]='Numpad 9'
  [kp_enter]='Numpad Enter'
  [kp_equals]='Numpad ='
  [kp_minus]='Numpad -'
  [kp_period]='Numpad .'
  [kp_plus]='Numpad +'
  [left]='Left'
  [leftbracket]='['
  [minus]='-'
  [multiply]='Numpad *'
  [num0]='0'
  [num1]='1'
  [num2]='2'
  [num3]='3'
  [num4]='4'
  [num5]='5'
  [num6]='6'
  [num7]='7'
  [num8]='8'
  [num9]='9'
  [numlock]='Num Lock'
  [pagedown]='Page Down'
  [pageup]='Page Up'
  [pause]='Pause'
  [period]='.'
  [print_screen]='Print'
  [quote]="'"
  [ralt]='Right Alt'
  [rctrl]='Right Ctrl'
  [right]='Right'
  [rightbracket]=']'
  [rshift]='Right Shift'
  [scroll_lock]='Scroll Lock'
  [semicolon]=';'
  [shift]='Left Shift'
  [slash]='/'
  [space]='Space'
  [subtract]='Numpad -'
  [tab]='Tab'
  [tilde]='`'
  [up]='Up'
)

# RetroPad mappings (config => retropad image name)
declare -A retropad_buttons_map
retropad_buttons_map=(
  [a]=a
  [b]=b
  [x]=x
  [y]=y
  [start]=start
  [select]=select
  [left]=dpad_left
  [right]=dpad_right
  [up]=dpad_up
  [down]=dpad_down
  [l]=l1
  [r]=r1
  [l2]=l2
  [r2]=r2
  [l3]=l3
  [r3]=r3
  [l_x_plus]='L Axis Right'
  [l_x_minus]='L Axis Left'
  [l_y_plus]='L Axis Up'
  [l_y_minus]='L Axis Down'
  [r_x_plus]='R Axis Right'
  [r_x_minus]='R Axis Left'
  [r_y_plus]='R Axis Up'
  [r_y_minus]='R Axis Down'
)

# Path to which custom controls will be tracked
controls_file="$tmp_ephemeral_dir/controls.json"

# Add theme overrides for adjusting logos
__add_system_theme() {
  local theme=$(xmlstarlet sel -t -v "/systemList/system[name='$system']/theme" "$HOME/.emulationstation/es_systems.cfg")
  local suffix
  if [ -n "$theme" ] && any_path_exists "{system_docs_dir}/logo-$theme.png"; then
    suffix="-$theme"
  else
    suffix=''
  fi

  __edit_json ".images.logo" "logo$suffix.png" "$controls_file"
}

# Add libretro keyboard controls
__add_keyboard_controls() {
  # Look up keyboard controls as long as the system doesn't use the keyboard
  # as an actual keyboard
  local uses_raw_keyboard=$(jq '.controls .keyboard_raw' "$(first_path '{system_docs_dir}/doc.json')")
  if [ "$uses_raw_keyboard" != 'true' ]; then
    for button_config in "${retroarch_keyboard_buttons_list[@]}"; do
      # Check if config exists before reading it
      if ! grep -qE "^input_player1_$button_config" /opt/retropie/configs/all/retroarch.cfg; then
        continue
      fi

      # Find the corresponding keyboard button
      local keyboard_key=$(crudini --get '/opt/retropie/configs/all/retroarch.cfg' '' "input_player1_$button_config" 2>/dev/null | tr -d '"')
      if [ -n "$keyboard_key" ]; then
        local keyboard_description=${keyboard_keys[$keyboard_key]:-$keyboard_key}
        local retropad_button=${retropad_buttons_map[$button_config]}
        __edit_json ".controls.keyboard.\"$keyboard_description\"" "$retropad_button" "$controls_file"
      fi
    done
  fi
}

# Add libretro hotkeys
__add_hotkey_controls() {
  local libretro_names=$(get_core_library_names)
  if [ -n "$libretro_names" ]; then
    # Figure out if there's a hotkey button
    local hotkey_button=$(__find_retroarch_hotkey_button 'enable_hotkey')

    for retroarch_action in "${retroarch_actions_list[@]}"; do
      local button_config=$(__find_retroarch_hotkey_button "$retroarch_action")
      if [ -n "$button_config" ]; then
        local retropad_button=${retropad_buttons_map[$button_config]}

        # We found a retropad button mapped as a hotkey -- go ahead and add it
        local buttons=''
        if [ -n "$hotkey_button" ]; then
          buttons="$hotkey_button,"
        fi
        buttons="$buttons$retropad_button"

        # Update the controls json
        local description=${retroarch_actions[$retroarch_action]}
        __edit_json ".controls.hotkeys.\"$buttons\"" "$description" "$controls_file"
      fi
    done
  fi
}

  # Add system-specific dynamic extensions
__source_system_extensions() {
  local extension_path=$(first_path '{system_docs_dir}/doc.sh')
  [ -n "$extension_path" ] && . "$extension_path"
}

# Adds system-specific extensions to the controls file (no-op)
__add_system_extensions() {
  return
}

# Finds the retropad button associated with the given hotkey action
__find_retroarch_hotkey_button() {
  local action=$1

  while read joypad_file; do
    if ! grep -qE "^(input_${action}_btn|input_player1_$action)" "$joypad_file"; then
      continue
    fi

    local button_id=$(crudini --get "$joypad_file" '' "input_${action}_btn" 2>/dev/null || crudini --get "$joypad_file" '' "input_player1_$action" 2>/dev/null)

    if [ -n "$button_id" ]; then
      # Look up the retropad button name (e.g. input_{button_name}_... = ...)
      local button=$(grep "$button_id" "$joypad_file" | grep -v "input_${action}_" | sed 's/_btn\|input_player1_\|input_//g' | cut -d' ' -f 1 | head -n 1)
      echo "$button"

      return
    fi
  done < <(__list_joypad_files)
}

# Builds a reference PDF using the given controls file overrides
__build_pdf() {
  local output_path=$1

  # Build full JSON variables for system (static + controls)
  jq -s '.[0] * .[1]' "$(first_path '{system_docs_dir}/doc.json')" "$controls_file" > "$build_dir/system.json"

  # Render Jinja => Markdown
  local reference_template=$(first_path '{docs_dir}/reference.html.jinja')
  jinja2 "$reference_template" "$build_dir/system.json" > "$build_dir/reference.html"

  # Render HTML => PDF
  chromium --headless --disable-gpu --run-all-compositor-stages-before-draw --print-to-pdf-no-header --print-to-pdf="$output_path" "$build_dir/reference.html" 2>/dev/null

  google-chrome "$build_dir/reference.html" &
}

# List all Retroarch configuration files which might contain controller info
__list_joypad_files() {
  find \
    /opt/retropie/configs/$system/retroarch.cfg \
    /opt/retropie/configs/all/retroarch.cfg \
    /opt/retropie/configs/all/retroarch-joypads \
    -name '*.cfg' 2>/dev/null
}

# Runs a JQ edit command on the following file, modifying it in-place
__edit_json() {
  local key=$1
  local value=$2
  local file=$3

  jq --arg value "$value" "$key = \$value" "$file" > "$file.replace"
  mv "$file.replace" "$file"
}
