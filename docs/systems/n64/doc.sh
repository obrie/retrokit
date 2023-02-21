# Keyboard Controls
keyboard_actions_list=(
  'Slot 0' 'Slot 1' 'Slot 2' 'Slot 3' 'Slot 4' 'Slot 6' 'Slot 7' 'Slot 8' 'Slot 9'
  Stop Reset Pause Mute
  'Save State' 'Load State'
  'Speed Down' 'Speed Up'
  'Increase Volume' 'Decrease Volume' 'Fast Forward' 'Frame Advance'
  Fullscreen Screenshot Gameshark
)
declare -Ag keyboard_actions
keyboard_actions=(
  ['Slot 0']='Slot 0'
  ['Slot 1']='Slot 1'
  ['Slot 2']='Slot 2'
  ['Slot 3']='Slot 3'
  ['Slot 4']='Slot 4'
  ['Slot 5']='Slot 5'
  ['Slot 6']='Slot 6'
  ['Slot 7']='Slot 7'
  ['Slot 8']='Slot 8'
  ['Slot 9']='Slot 9'
  [Stop]='Quit'
  [Reset]='Reset'
  [Pause]='Pause'
  [Mute]='Mute'
  ['Save State']='State: Save'
  ['Load State']='State: Load'
  ['Speed Down']='Speed -'
  ['Speed Up']='Speed +'
  ['Increase Volume']='Volume +'
  ['Decrease Volume']='Volume -'
  ['Fast Forward']='Fast Fwd'
  ['Frame Advance']='Frame +'
  [Fullscreen]='Fullscreen'
  [Screenshot]='Screenshot'
  [Gameshark]='Gameshark'
)

declare -Ag keyboard_action_defaults
keyboard_action_defaults=(
  ['Slot 0']=48
  ['Slot 1']=49
  ['Slot 2']=50
  ['Slot 3']=51
  ['Slot 4']=52
  ['Slot 5']=53
  ['Slot 6']=54
  ['Slot 7']=55
  ['Slot 8']=56
  ['Slot 9']=57
  [Stop]=27
  [Fullscreen]=0
  ['Save State']=286
  ['Load State']=288
  ['Increment Slot']=0
  [Reset]=290
  ['Speed Down']=291
  ['Speed Up']=292
  [Screenshot]=293
  [Pause]=112
  [Mute]=109
  ['Increase Volume']=93
  ['Decrease Volume']=91
  ['Fast Forward']=102
  ['Frame Advance']=47
  [Gameshark]=103
)

# SDL Keycode map
declare -Ag sdl1_map
sdl1_map=(
  [8]='Backspace'
  [9]='Tab'
  [13]='Return'
  [27]='Esc'
  [32]='Space'
  [33]='!'
  [34]='"'
  [35]='#'
  [36]='$'
  [37]='%'
  [38]='*'
  [39]="'"
  [40]='('
  [41]=')'
  [42]='*'
  [43]='+'
  [44]=','
  [45]='-'
  [46]='.'
  [47]='/'
  [48]='0'
  [49]='1'
  [50]='2'
  [51]='3'
  [52]='4'
  [53]='5'
  [54]='6'
  [55]='7'
  [56]='8'
  [57]='9'
  [58]=':'
  [59]=';'
  [60]='<'
  [61]='='
  [62]='>'
  [63]='?'
  [64]='@'
  [91]='['
  [92]='\\'
  [93]=']'
  [94]='^'
  [95]='_'
  [96]='`'
  [97]='a'
  [98]='b'
  [99]='c'
  [100]='d'
  [101]='e'
  [102]='f'
  [103]='g'
  [104]='h'
  [105]='i'
  [106]='j'
  [107]='k'
  [108]='l'
  [109]='m'
  [110]='n'
  [111]='o'
  [112]='p'
  [113]='q'
  [114]='r'
  [115]='s'
  [116]='t'
  [117]='u'
  [118]='v'
  [119]='w'
  [120]='x'
  [121]='y'
  [122]='z'
  [127]='Delete'
  [1073741881]='Caps Lock'
  [1073741882]='F1'
  [1073741883]='F2'
  [1073741884]='F3'
  [1073741885]='F4'
  [1073741886]='F5'
  [1073741887]='F6'
  [1073741888]='F7'
  [1073741889]='F8'
  [1073741890]='F9'
  [1073741891]='F10'
  [1073741892]='F11'
  [1073741893]='F12'
  [1073741894]='Prt Screen'
  [1073741895]='Scroll Lock'
  [1073741896]='Pause'
  [1073741897]='Insert'
  [1073741898]='Home'
  [1073741899]='Pg Up'
  [1073741901]='End'
  [1073741902]='Pg Down'
  [1073741903]='Right'
  [1073741904]='Left'
  [1073741905]='Down'
  [1073741906]='Up'
  [1073741908]='Numpad /'
  [1073741909]='Numpad *'
  [1073741910]='Numpad -'
  [1073741911]='Numpad +'
  [1073741912]='Numpad Enter'
  [1073741913]='Numpad 1'
  [1073741914]='Numpad 2'
  [1073741915]='Numpad 3'
  [1073741916]='Numpad 4'
  [1073741917]='Numpad 5'
  [1073741918]='Numpad 6'
  [1073741919]='Numpad 7'
  [1073741920]='Numpad 8'
  [1073741921]='Numpad 9'
  [1073741922]='Numpad 0'
  [1073741923]='Numpad .'
  [1073741926]='^'
  [1073741927]='Numpad ='
  [1073741928]='F13'
  [1073741929]='F14'
  [1073741930]='F15'
  [1073741941]='Help'
  [1073741942]='Menu'
  [1073741946]='Undo'
  [1073741978]='Sys Req'
  [1073742048]='Left Ctrl'
  [1073742049]='Left Shift'
  [1073742050]='Left Alt'
  [1073742051]='Left GUI'
  [1073742052]='Right Ctrl'
  [1073742053]='Right Shift'
  [1073742054]='Right Alt'
  [1073742055]='Right GUI'
  [1073742081]='Mode'
)

# Add n64-specific mupen64plus controls
__add_system_extensions() {
  if has_emulator 'mupen64plus'; then
    __add_mupen64plus_keyboard_controls
  fi
}

__add_mupen64plus_keyboard_controls() {
  local config_file="$retropie_system_config_dir/mupen64plus.cfg"
  local edit_args=()

  for keyboard_action in "${keyboard_actions_list[@]}"; do
    local config_name="Kbd Mapping $keyboard_action"
    local input_id=

    # Either use the default key or find one in the config
    if [ ! -f "$config_file" ] || ! grep -Eq "^$config_name " "$config_file"; then
      input_id="${keyboard_action_defaults[$keyboard_action]}"
    else
      input_id=$(crudini --get "$config_file" 'CoreEvents' "$config_name" 2>/dev/null | tr -d '"')
    fi

    if [ -n "$input_id" ] && [ "${sdl1_map[$input_id]}" != '' ]; then
      local keyboard_action_description=${keyboard_actions[$keyboard_action]}
      local key_description=${sdl1_map[$input_id]}

      edit_args+=(".controls.keyboard.\"$key_description\"" "$keyboard_action_description")
    fi
  done

  if [ ${#edit_args[@]} -gt 0 ]; then
    json_edit "$doc_data_file" "${edit_args[@]}"
  fi
}
