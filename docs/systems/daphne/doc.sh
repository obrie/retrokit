#!/bin/bash

# Daphne Actions
daphne_actions_list=(
  UP DOWN LEFT RIGHT
  COIN1 COIN2 START1 START2
  BUTTON1 BUTTON2 BUTTON3 SKILL1 SKILL2 SKILL3
  QUIT PAUSE
  RESET TILT SCREENSHOT CONSOLE TEST
)
declare -Ag daphne_actions
daphne_actions=(
  [UP]='Up'
  [DOWN]='Down'
  [LEFT]='Left'
  [RIGHT]='Right'
  [COIN1]='Coin P1'
  [COIN2]='Coin P2'
  [START1]='Start P1'
  [START2]='Start P2'
  [BUTTON1]='Fire #1'
  [BUTTON2]='Fire #2'
  [BUTTON3]='Button #3'
  [SKILL1]='Skill: Cadet'
  [SKILL2]='Skill: Captain'
  [SKILL3]='Skill: Space Ace'
  [QUIT]='Quit'
  [PAUSE]='Pause'
  [RESET]='Reset'
  [TILT]='Tilt'
  [SCREENSHOT]='Screenshot'
  [CONSOLE]='Service Mode'
  [TEST]='Test Mode'
)

# Daphne key human-readable descriptions
declare -Ag daphne_keys
daphne_keys=(
  [BACKSPACE]='Backspace'
  [TAB]='Tab'
  [RETURN]='Enter'
  [ESCAPE]='Esc'
  [SPACE]='Space'
  [QUOTE]="'"
  [COMMA]=','
  [MINUS]='-'
  [PERIOD]='.'
  [SLASH]='/'
  [0]='0'
  [1]='1'
  [2]='2'
  [3]='3'
  [4]='4'
  [5]='5'
  [6]='6'
  [7]='7'
  [8]='8'
  [9]='9'
  [SEMICOLON]=';'
  [EQUALS]='='
  [LEFTBRACKET]='['
  [BACKSLASH]='\'
  [RIGHTBRACKET]=']'
  [BACKQUOTE]='`'
  [a]='A'
  [b]='B'
  [c]='C'
  [d]='D'
  [e]='E'
  [f]='F'
  [g]='G'
  [h]='H'
  [i]='I'
  [j]='J'
  [k]='K'
  [l]='L'
  [m]='M'
  [n]='N'
  [o]='O'
  [p]='P'
  [q]='Q'
  [r]='R'
  [s]='S'
  [t]='T'
  [u]='U'
  [v]='V'
  [w]='W'
  [x]='X'
  [y]='Y'
  [z]='Z'
  [DELETE]='Del'
  [CAPSLOCK]='Caps Lock'
  [F1]='F1'
  [F2]='F2'
  [F3]='F3'
  [F4]='F4'
  [F5]='F5'
  [F6]='F6'
  [F7]='F7'
  [F8]='F8'
  [F9]='F9'
  [F10]='F10'
  [F11]='F11'
  [F12]='F12'
  [PRINTSCREEN]='Prt Screen'
  [SCROLLLOCK]='Scroll Lock'
  [INSERT]='Insert'
  [HOME]='Home'
  [PAGEUP]='Pg Up'
  [END]='End'
  [PAGEDOWN]='Pg Down'
  [RIGHT]='Right'
  [LEFT]='Left'
  [DOWN]='Down'
  [UP]='Up'
  [NUMLOCKCLEAR]='Num Lk'
  [KP_DIVIDE]='Numpad /'
  [KP_MULTIPLY]='Numpad *'
  [KP_MINUS]='Numpad -'
  [KP_PLUS]='Numpad +'
  [KP_ENTER]='Numpad Enter'
  [KP_1]='Numpad 1'
  [KP_2]='Numpad 2'
  [KP_3]='Numpad 3'
  [KP_4]='Numpad 4'
  [KP_5]='Numpad 5'
  [KP_6]='Numpad 6'
  [KP_7]='Numpad 7'
  [KP_8]='Numpad 8'
  [KP_9]='Numpad 9'
  [KP_0]='Numpad 0'
  [KP_PERIOD]='Numpad .'
  [KP_EQUALS]='Numpad ='
  [LCTRL]='Left Ctrl'
  [LSHIFT]='Left Shift'
  [LALT]='Left Alt'
  [RCTRL]='Right Ctrl'
  [RSHIFT]='Right Shift'
  [RALT]='Right Alt'
)

hypseus_mapping_file='/opt/retropie/configs/daphne/hypinput.ini'

# Add daphne-specific controls
__add_system_extensions() {
  __add_hypseus_keyboard_controls "${@}"
}

# Add keyboard mappings
__add_hypseus_keyboard_controls() {
  local core_options_file=$1
  local edit_args=()

  for action in ${daphne_actions_list[@]}; do
    local action_description=${daphne_actions[$action]}
    local config_values=$(grep -E "^KEY_$action =" "$hypseus_mapping_file" | tail -n 1 | sed "s/KEY_$action = //g")
    IFS=' ' read -r key1 key2 button axis <<< "$config_values"

    local key_description=''

    # Keyboard button 1
    if [ "$key1" != '0' ]; then
      local key1_id=${key1//SDLK_/}
      local key1_description=${daphne_keys[$key1_id]}
      if [ "$key1_description" == '\' ]; then
        key1_description='\\'
      fi

      key_description=$key1_description
    fi

    # Keyboard button 2
    if [ "$key2" != '0' ]; then
      local key2_id=${key2//SDLK_/}
      local key2_description=${daphne_keys[$key2_id]}
      if [ "$key2_description" == '\' ]; then
        key2_description='\\'
      fi

      if [ -z "$key_description" ]; then
        key_description=$key2_description
      else
        key_description="$key_description ($key2_description)"
      fi
    fi

    if [ -n "$key_description" ]; then
      edit_args+=(".controls.keyboard.\"$key_description\"" "$action_description")
    fi
  done

  if [ ${#edit_args[@]} -gt 0 ]; then
    json_edit "$doc_data_file" "${edit_args[@]}"
  fi
}
