# Keyboard Controls
keyboard_actions_list=(
  pause restart mapper
  swapimg scrshot recwave
  video shutdown select
  capmouse incval decval
  cycledown cycleup speedlock
  cgacomp fullscr
)
declare -Ag keyboard_actions
keyboard_actions=(
  [pause]='Pause'
  [restart]='Restart'
  [mapper]='Mapper'
  [swapimg]='Swap Disk'
  [scrshot]='Screenshot'
  [recwave]='Record: Audio'
  [video]='Record: Video'
  [shutdown]='Quit'
  [select]='Knob Select'
  [capmouse]='Toggle Mouse'
  [incval]='Knob +'
  [decval]='Knob -'
  [cycledown]='Cycles -'
  [cycleup]='Cycles +'
  [speedlock]='Turbo'
  [cgacomp]='CGA Comp'
  [fullscr]='Full Screen'
  [decfskip]='Frameskip -'
  [incfskip]='Frameskip +'
  [caprawmidi]='Record: MIDI'
  [caprawopl]='Record: OPL'
)

declare -Ag keyboard_action_defaults
keyboard_action_defaults=(
  [pause]='lalt,p'
  [restart]='lctrl,lalt,home'
  [mapper]='lctrl,f1'
  [swapimg]='lctrl,f4'
  [scrshot]='lctrl,f5'
  [recwave]='lctrl,f6'
  [video]='lctrl,f7'
  [shutdown]='lctrl,f9'
  [select]='f10'
  [capmouse]='lctrl,f10'
  [incval]='f11'
  [decval]='lalt,f11'
  [cycledown]='lctrl,f11'
  [cycleup]='lctrl,f12'
  [speedlock]='lalt,f12'
  [cgacomp]='f12'
  [fullscr]='lalt,enter'
)

# Keyname map
declare -Ag key_name_map
key_name_map=(
  [esc]='Esc'
  [f1]='F1'
  [f2]='F2'
  [f3]='F3'
  [f4]='F4'
  [f5]='F5'
  [f6]='F6'
  [f7]='F7'
  [f8]='F8'
  [f9]='F9'
  [f10]='F10'
  [f11]='F11'
  [f12]='F12'
  [grave]='~'
  [1]='1'
  [2]='2'
  [3]='3'
  [4]='4'
  [5]='5'
  [6]='6'
  [7]='7'
  [8]='8'
  [9]='9'
  [0]='0'
  [minus]='-'
  [equals]='='
  [bspace]='Backspace'
  [tab]='Tab'
  [a]='a'
  [b]='b'
  [c]='c'
  [d]='d'
  [e]='e'
  [f]='f'
  [g]='g'
  [h]='h'
  [i]='i'
  [j]='j'
  [k]='k'
  [l]='l'
  [m]='m'
  [n]='n'
  [o]='o'
  [p]='p'
  [q]='q'
  [r]='r'
  [s]='s'
  [t]='t'
  [u]='u'
  [v]='v'
  [w]='w'
  [x]='x'
  [y]='y'
  [z]='z'
  [lbracket]='['
  [rbracket]=']'
  [enter]='Enter'
  [capslock]='Caps Lock'
  [semicolon]=';'
  [quote]='"'
  [backslash]='\\'
  [lshift]='Left Shift'
  [lessthan]='<'
  [comma]=','
  [period]='.'
  [slash]='/'
  [rshift]='Right Shift'
  [lctrl]='Left Ctrl'
  [lgui]='Left GUI'
  [lalt]='Left Alt'
  [space]='Space'
  [ralt]='Right Alt'
  [rgui]='Right GUI'
  [rctrl]='Right Ctrl'
  [printscreen]='Prt Scrn'
  [scrolllock]='Scroll Lock'
  [pause]='Pause'
  [insert]='Insert'
  [home]='Home'
  [pageup]='Pg Up'
  [delete]='Delete'
  [end]='End'
  [pagedown]='Pg Down'
  [up]='Up'
  [left]='Left'
  [down]='Down'
  [right]='Right'
  [numlock]='Num Lock'
  [kp_0]='0'
  [kp_1]='1'
  [kp_2]='2'
  [kp_3]='3'
  [kp_4]='4'
  [kp_5]='5'
  [kp_6]='6'
  [kp_7]='7'
  [kp_8]='8'
  [kp_9]='9'
  [kp_divide]='Numpad /'
  [kp_multiply]='Numpad *'
  [kp_minus]='Numpad -'
  [kp_plus]='Numpad +'
  [kp_enter]='Numpad Enter'
  [kp_period]='Numpad .'
)

# Add pc-specific mupen64plus controls
__add_system_extensions() {
  # Look up the default mapperfile
  local mapperfile_path=$(crudini --get /opt/retropie/configs/pc/dosbox-staging.conf 'sdl' 'mapperfile')
  if [ -z "$mapperfile_path" ]; then
    return
  fi


  local config_file="/opt/retropie/configs/pc/$mapperfile_path"
  local edit_args=()

  if [ -f "$config_file" ]; then
    # Map scan codes to their corresponding key name
    declare -A key_codes
    while IFS=' ' read key_name scancode; do
      key_codes[$scancode]=$key_name
    done < <(grep -E '^key_' "$config_file" | sed 's/key \+//g; s/"//g; s/^key_//g')

    # Map modifier codes to their corresponding key name
    while IFS=' ' read modifier_id scancode1 scancode2; do
      key_codes["mod$modifier_id"]=${key_codes[$scancode1]}
    done < <(grep -E '^mod_' "$config_file" | sed 's/key \+//g; s/"//g; s/^mod_//g')
  fi

  for keyboard_action in "${keyboard_actions_list[@]}"; do
    local config_name="hand_$keyboard_action"
    local input_config=

    # Either use the default key or find one in the config
    local key_names_csv=
    if [ ! -f "$config_file" ]; then
      key_names_csv=${keyboard_action_defaults[$keyboard_action]}
    else
      key_codes_csv=$(grep "hand_$keyboard_action" "$config_file" | grep -oE '".*"' | sed "s/\"//g; s/key \+//g; s/ \+/,/g")
      if [ -z "$key_codes_csv" ]; then
        continue
      fi

      # Map key codes to the corresponding key name
      while read key_code; do
        key_names_csv="$key_names_csv${key_codes[$key_code]},"
      done < <(echo "$key_codes_csv" | tr ',' '\n' | sort -r)
      key_names_csv=${key_names_csv::-1}
    fi

    echo "key_names_csv: $key_names_csv"
    if [ -n "$key_names_csv" ]; then
      # Generate a description ofthe key(s)
      local key_description=
      while read key_name; do
        local key=${key_name_map[$key_name]}
        local key_description="$key_description$key + "
      done < <(echo "$key_names_csv" | tr ',' '\n')
      key_description=${key_description::-3}

      # Generate a description fo the action
      local keyboard_action_description=${keyboard_actions[$keyboard_action]}

      edit_args+=(".controls.keyboard.\"$key_description\"" "$keyboard_action_description")
    fi
  done

  if [ ${#edit_args[@]} -gt 0 ]; then
    json_edit "$doc_data_file" "${edit_args[@]}"
  fi
}
