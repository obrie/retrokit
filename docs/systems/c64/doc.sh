#!/bin/bash

# VICE Controls
vice_actions_list=(
  vkbd statusbar joyport_switch reset
  warp_mode aspect_ratio_toggle zoom_mode_toggle
  datasette_toggle_hotkeys datasette_start datasette_stop datasette_rewind datasette_forward datasette_reset
)
declare -Ag vice_actions
vice_actions=(
  [vkbd]='Keyboard'
  [statusbar]='Statusbar'
  [joyport_switch]='Swap Joyport'
  [reset]='Reset'
  [warp_mode]='Warp Mode'
  [aspect_ratio_toggle]='Toggle Aspect'
  [zoom_mode_toggle]='Toggle Zoom'
  [datasette_toggle_hotkeys]='Tape: Toggle'
  [datasette_start]='Tape: Start'
  [datasette_stop]='Tape: Stop'
  [datasette_rewind]='Tape: Rewind'
  [datasette_forward]='Tape: Forward'
  [datasette_reset]='Tape: Reset'
)

declare -Ag vice_action_defaults
vice_action_defaults=(
  [statusbar]='RETROK_F12'
  [joyport_switch]='RETROK_RCTRL'
  [reset]='RETROK_END'
  [datasette_start]='RETROK_UP'
  [datasette_stop]='RETROK_DOWN'
  [datasette_rewind]='RETROK_LEFT'
  [datasette_forward]='RETROK_RIGHT'
)

# Retro Key human-readable descriptions
declare -Ag retro_keys
retro_keys=(
  [JOYSTICK_FIRE]='Fire Button 1'
  [JOYSTICK_FIRE2]='Fire Button 2'
  [MOUSE_FASTER]='Mouse Faster'
  [MOUSE_SLOWER]='Mouse Slower'
  [RETROK_0]='0'
  [RETROK_1]='1'
  [RETROK_2]='2'
  [RETROK_3]='3'
  [RETROK_4]='4'
  [RETROK_5]='5'
  [RETROK_6]='6'
  [RETROK_7]='7'
  [RETROK_8]='8'
  [RETROK_9]='9'
  [RETROK_ASTERISK]='*'
  [RETROK_BACKQUOTE]='`'
  [RETROK_BACKSLASH]='\\'
  [RETROK_BACKSPACE]='Backspace'
  [RETROK_CARET]='^'
  [RETROK_COLON]=':'
  [RETROK_COMMA]=','
  [RETROK_DELETE]='Delete'
  [RETROK_DOWN]='Down'
  [RETROK_END]='End'
  [RETROK_EQUALS]='='
  [RETROK_ESCAPE]='Esc (RUN/STOP)'
  [RETROK_F10]='F10'
  [RETROK_F11]='F11'
  [RETROK_F12]='F12'
  [RETROK_F13]='F13'
  [RETROK_F14]='F14'
  [RETROK_F15]='F15'
  [RETROK_F1]='F1'
  [RETROK_F2]='F2'
  [RETROK_F3]='F3'
  [RETROK_F4]='F4'
  [RETROK_F5]='F5'
  [RETROK_F6]='F6'
  [RETROK_F7]='F7'
  [RETROK_F8]='F8'
  [RETROK_F9]='F9'
  [RETROK_GREATER]='>'
  [RETROK_HOME]='Home (CLR)'
  [RETROK_INSERT]='Insert (£)'
  [RETROK_KP0]='Numpad 0'
  [RETROK_KP1]='Numpad 1'
  [RETROK_KP2]='Numpad 2'
  [RETROK_KP3]='Numpad 3'
  [RETROK_KP4]='Numpad 4'
  [RETROK_KP5]='Numpad 5'
  [RETROK_KP6]='Numpad 6'
  [RETROK_KP7]='Numpad 7'
  [RETROK_KP8]='Numpad 8'
  [RETROK_KP9]='Numpad 9'
  [RETROK_KP_DIVIDE]='Numpad /'
  [RETROK_KP_ENTER]='Numpad Enter'
  [RETROK_KP_EQUALS]='Numpad ]='
  [RETROK_KP_MINUS]='Numpad -'
  [RETROK_KP_MULTIPLY]='Numpad *'
  [RETROK_KP_PERIOD]='Numpad .'
  [RETROK_KP_PLUS]='Numpad +'
  [RETROK_LALT]='Left Alt'
  [RETROK_LCTRL]='Left Ctrl (Commodore)'
  [RETROK_LEFTBRACKET]='[ (@)'
  [RETROK_LEFTPAREN]='('
  [RETROK_LEFT]='Left'
  [RETROK_LESS]='<'
  [RETROK_LSHIFT]='Left Shift'
  [RETROK_LSUPER]='Left Super'
  [RETROK_MINUS]='-'
  [RETROK_PAGEDOWN]='PgUp'
  [RETROK_PAGEUP]='PgDn'
  [RETROK_PERIOD]='.'
  [RETROK_PLUS]='+'
  [RETROK_QUOTE]="'"
  [RETROK_RALT]='Right Alt'
  [RETROK_RCTRL]='Right Ctrl'
  [RETROK_RETURN]='Return'
  [RETROK_RIGHTBRACKET]=']'
  [RETROK_RIGHTPAREN]=')'
  [RETROK_RIGHT]='Right'
  [RETROK_RSHIFT]='Right Shift'
  [RETROK_RSUPER]='Right Super'
  [RETROK_SEMICOLON]=';'
  [RETROK_SLASH]='/'
  [RETROK_SPACE]='Space'
  [RETROK_TAB]='Tab'
  [RETROK_UNDERSCORE]='_'
  [RETROK_UP]='Up'
  [RETROK_a]='A'
  [RETROK_b]='B'
  [RETROK_c]='C'
  [RETROK_d]='D'
  [RETROK_e]='E'
  [RETROK_f]='F'
  [RETROK_g]='G'
  [RETROK_h]='H'
  [RETROK_i]='I'
  [RETROK_j]='J'
  [RETROK_k]='K'
  [RETROK_l]='L'
  [RETROK_m]='M'
  [RETROK_n]='N'
  [RETROK_o]='O'
  [RETROK_p]='P'
  [RETROK_q]='Q'
  [RETROK_r]='R'
  [RETROK_s]='S'
  [RETROK_t]='T'
  [RETROK_u]='U'
  [RETROK_v]='V'
  [RETROK_w]='W'
  [RETROK_x]='X'
  [RETROK_y]='Y'
  [RETROK_z]='Z'
  [SWITCH_JOYPORT]='Swap Joyport'
  [TOGGLE_STATUSBAR]='Statusbar'
  [TOGGLE_VKBD]='Keyboard'
)

# VICE RetroPad Mapper
vice_mapper_buttons=(
  start select
  a b x y
  l r l2 r2 l3 r3
  lu ld ll lr
  ru rd rl rr
)
declare -Ag vice_mapper_retropad_map
vice_mapper_retropad_map=(
  [start]=start
  [select]=select
  [a]=a
  [b]=b
  [x]=x
  [y]=y
  [l]=l1
  [r]=r1
  [l2]=l2
  [r2]=r2
  [l3]=l3
  [r3]=r3
  [lu]='L Axis Up'
  [ld]='L Axis Down'
  [ll]='L Axis Left'
  [lr]='L Axis Right'
  [ru]='R Axis Up'
  [rd]='R Axis Down'
  [rl]='R Axis Left'
  [rr]='R Axis Right'
)
declare -Ag vice_mapper_defaults
vice_mapper_defaults=(
  [select]='TOGGLE_VKBD'
  [a]='JOYSTICK_FIRE2'
  [b]='JOYSTICK_FIRE'
  [x]='RETROK_SPACE'
  [l2]='RETROK_ESCAPE'
  [r2]='RETROK_RETURN'
)

# Determines whether the given ROM has any doc overrides
__has_rom_overrides() {
  local core_options_file=$1
  if [ -f "$core_options_file" ]; then
    comm -13 <(sort /opt/retropie/configs/c64/retroarch-core-options.cfg) <(sort "$core_options_file") | grep -q "vice_mapper"
  else
    return 1
  fi
}

# Add c64-specific controls
__add_system_extensions() {
  __add_keyboard_controls
  __add_vice_keyboard_controls "${@}"
  __add_vice_retropad_controls "${@}"
}

# Add keyboard mappings
__add_vice_keyboard_controls() {
  local core_options_file=$1
  local edit_args=()

  local datasette_keys_enabled=$(crudini -- get "$core_options_file" '' vice_datasette_hotkeys 2>/dev/null | tr -d '"')

  for vice_action in ${vice_actions_list[@]}; do
    local core_option_name="vice_mapper_$vice_action"
    local retro_key=

    # Either use the default key or find one in the core options
    if ! grep -Eq "^$core_option_name " "$core_options_file"; then
      retro_key="${vice_action_defaults[$vice_action]}"
    else
      retro_key=$(crudini --get "$core_options_file" '' "$core_option_name" 2>/dev/null | tr -d '"')
    fi

    # Check if there's a setting that disables this action
    local enabled=true
    if [[ "$vice_action" == *datasette* ]] && [ "$vice_action" != 'datasette_toggle_hotkeys' ] && [ "$datasette_keys_enabled" != 'true' ]; then
      enabled=false
    fi

    if [ "$enabled" == 'true' ] && [ -n "$retro_key" ] && [ "$retro_key" != '---' ]; then
      local vice_action_description=${vice_actions[$vice_action]}
      local retro_key_description=${retro_keys[$retro_key]}

      edit_args+=(".controls.keyboard.\"$retro_key_description\"" "$vice_action_description")
    fi
  done

  if [ ${#edit_args[@]} -gt 0 ]; then
    json_edit "$doc_data_file" "${edit_args[@]}"
  fi
}

# Add controller mappings
__add_vice_retropad_controls() {
  local core_options_file=$1
  local edit_args=()

  local datasette_keys_enabled=$(crudini -- get "$core_options_file" '' vice_datasette_hotkeys 2>/dev/null | tr -d '"')

  for vice_button in ${vice_mapper_buttons[@]}; do
    local core_option_name="vice_mapper_$vice_button"

    # Either use the default key or find one in the core options
    if ! grep -Eq "^$core_option_name " "$core_options_file"; then
      retro_key="${vice_mapper_defaults[$vice_button]}"
    else
      retro_key=$(crudini --get "$core_options_file" '' "$core_option_name" 2>/dev/null | tr -d '"')
    fi

    # Check if there's a setting that disables this action
    local enabled=true
    if [[ "$vice_action" == *datasette* ]] && [ "$vice_action" != 'datasette_toggle_hotkeys' ] && [ "$datasette_keys_enabled" != 'true' ]; then
      enabled=false
    fi

    if [ -n "$retro_key" ] && [ "$retro_key" != '---' ]; then
      local retropad_button=${vice_mapper_retropad_map[$vice_button]}
      local retro_key_description=${retro_keys[$retro_key]}

      edit_args+=(".controls.retropad.\"$retropad_button\"" "$retro_key_description")
    fi
  done

  if [ ${#edit_args[@]} -gt 0 ]; then
    json_edit "$doc_data_file" "${edit_args[@]}"
  fi
}
