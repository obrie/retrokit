[ControlMapping]
Up = 1-19,10-19
Down = 1-20,10-20
Left = 1-21,10-21
Right = 1-22,10-22
Circle = 1-52,10-190
Cross = 1-54,10-189
Square = 1-29,10-191
Triangle = 1-47,10-188
Start = 1-62,10-197
Select = 1-66,10-196
L = 1-45,10-194
R = 1-51,10-195
An.Up = 1-37,10-4003
An.Down = 1-39,10-4002
An.Left = 1-38,10-4001
An.Right = 1-40,10-4000
Analog limiter = 1-60
RapidFire = 1-59
Unthrottle = 1-61
SpeedToggle = 1-68
Pause = 1-111
Rewind = 1-67

https://github.com/hrydgard/ppsspp/blob/master/Core/KeyMap.cpp

#!/usr/bin/env bash

redream_config_path="$configdir/dreamcast/redream/redream.cfg"

function onstart_redream_joystick() {
    iniConfig '=' '' "$redream_config_path"

    local profile_id=$(grep "name:$DEVICE_GUID" "$redream_config_path" | head -n 1 | grep -oE '^[^=]+')
    if [ -z "$profile_id" ]; then
        last_profile_id=$(grep -oE '^profile[0-9]+' "$redream_config_path" | sort | tail -n 1)
        
        profile_id=$()
    fi
    iniGet 'input_joypad_driver'
    local input_joypad_driver="$ini_value"
    if [[ -z "$input_joypad_driver" ]]; then
        input_joypad_driver="udev"
    fi

    -i //newInputConfig -t attr -n "type" -v "$DEVICE_TYPE" \
    -i //newInputConfig -t attr -n "deviceName" -v "$DEVICE_NAME" \
    -i //newInputConfig -t attr -n "deviceGUID" -v "$DEVICE_GUID" \
    name:keyboard0,type:controller,deadzone:12,crosshair:1
}

function onstart_redream_keyboard() {
    declare -Ag keymap
  NKCODE_BUTTON_CROSS = 23, // trackpad or X button(Xperia Play) is pressed
  NKCODE_BUTTON_CROSS_PS3 = 96, // PS3 X button is pressed
  NKCODE_BUTTON_CIRCLE = 1004, // Special custom keycode generated from 'O' button by our java code. Or 'O' button if Alt is pressed (TODO)
  NKCODE_BUTTON_CIRCLE_PS3 = 97, // PS3 O button is pressed
  NKCODE_BUTTON_SQUARE = 99, // Square button(Xperia Play) is pressed
  NKCODE_BUTTON_TRIANGLE = 100, // 'Triangle button(Xperia Play) is pressed
  NKCODE_DPAD_UP = 19,
  NKCODE_DPAD_DOWN = 20,
  NKCODE_DPAD_LEFT = 21,
  NKCODE_DPAD_RIGHT = 22,
  NKCODE_DPAD_CENTER = 23,
  NKCODE_UNKNOWN = 0,
  NKCODE_SOFT_LEFT = 1,
  NKCODE_SOFT_RIGHT = 2,
  NKCODE_HOME = 3,
  NKCODE_BACK = 4,
  NKCODE_CALL = 5,
  NKCODE_ENDCALL = 6,
  NKCODE_0 = 7,
  NKCODE_1 = 8,
  NKCODE_2 = 9,
  NKCODE_3 = 10,
  NKCODE_4 = 11,
  NKCODE_5 = 12,
  NKCODE_6 = 13,
  NKCODE_7 = 14,
  NKCODE_8 = 15,
  NKCODE_9 = 16,
  NKCODE_STAR = 17,
  NKCODE_POUND = 18,
  NKCODE_VOLUME_UP = 24,
  NKCODE_VOLUME_DOWN = 25,
  NKCODE_POWER = 26,
  NKCODE_CAMERA = 27,
  NKCODE_CLEAR = 28,
  NKCODE_A = 29,
  NKCODE_B = 30,
  NKCODE_C = 31,
  NKCODE_D = 32,
  NKCODE_E = 33,
  NKCODE_F = 34,
  NKCODE_G = 35,
  NKCODE_H = 36,
  NKCODE_I = 37,
  NKCODE_J = 38,
  NKCODE_K = 39,
  NKCODE_L = 40,
  NKCODE_M = 41,
  NKCODE_N = 42,
  NKCODE_O = 43,
  NKCODE_P = 44,
  NKCODE_Q = 45,
  NKCODE_R = 46,
  NKCODE_S = 47,
  NKCODE_T = 48,
  NKCODE_U = 49,
  NKCODE_V = 50,
  NKCODE_W = 51,
  NKCODE_X = 52,
  NKCODE_Y = 53,
  NKCODE_Z = 54,
  NKCODE_COMMA = 55,
  NKCODE_PERIOD = 56,
  NKCODE_ALT_LEFT = 57,
  NKCODE_ALT_RIGHT = 58,
  NKCODE_SHIFT_LEFT = 59,
  NKCODE_SHIFT_RIGHT = 60,
  NKCODE_TAB = 61,
  NKCODE_SPACE = 62,
  NKCODE_SYM = 63,
  NKCODE_EXPLORER = 64,
  NKCODE_ENVELOPE = 65,
  NKCODE_ENTER = 66,
  NKCODE_DEL = 67,
  NKCODE_GRAVE = 68,
  NKCODE_MINUS = 69,
  NKCODE_EQUALS = 70,
  NKCODE_LEFT_BRACKET = 71,
  NKCODE_RIGHT_BRACKET = 72,
  NKCODE_BACKSLASH = 73,
  NKCODE_SEMICOLON = 74,
  NKCODE_APOSTROPHE = 75,
  NKCODE_SLASH = 76,
  NKCODE_AT = 77,
  NKCODE_NUM = 78,
  NKCODE_HEADSETHOOK = 79,
  NKCODE_FOCUS = 80,
  NKCODE_PLUS = 81,
  NKCODE_MENU = 82,
  NKCODE_NOTIFICATION = 83,
  NKCODE_SEARCH = 84,
  NKCODE_MEDIA_PLAY_PAUSE = 85,
  NKCODE_MEDIA_STOP = 86,
  NKCODE_MEDIA_NEXT = 87,
  NKCODE_MEDIA_PREVIOUS = 88,
  NKCODE_MEDIA_REWIND = 89,
  NKCODE_MEDIA_FAST_FORWARD = 90,
  NKCODE_MUTE = 91,
  NKCODE_PAGE_UP = 92,
  NKCODE_PAGE_DOWN = 93,
  NKCODE_PICTSYMBOLS = 94,
  NKCODE_SWITCH_CHARSET = 95,
  NKCODE_BUTTON_A = 96,
  NKCODE_BUTTON_B = 97,
  NKCODE_BUTTON_C = 98,
  NKCODE_BUTTON_X = 99,
  NKCODE_BUTTON_Y = 100,
  NKCODE_BUTTON_Z = 101,
  NKCODE_BUTTON_L1 = 102,
  NKCODE_BUTTON_R1 = 103,
  NKCODE_BUTTON_L2 = 104,
  NKCODE_BUTTON_R2 = 105,
  NKCODE_BUTTON_THUMBL = 106,
  NKCODE_BUTTON_THUMBR = 107,
  NKCODE_BUTTON_START = 108,
  NKCODE_BUTTON_SELECT = 109,
  NKCODE_BUTTON_MODE = 110,
  NKCODE_ESCAPE = 111,
  NKCODE_FORWARD_DEL = 112,
  NKCODE_CTRL_LEFT = 113,
  NKCODE_CTRL_RIGHT = 114,
  NKCODE_CAPS_LOCK = 115,
  NKCODE_SCROLL_LOCK = 116,
  NKCODE_META_LEFT = 117,
  NKCODE_META_RIGHT = 118,
  NKCODE_FUNCTION = 119,
  NKCODE_SYSRQ = 120,
  NKCODE_BREAK = 121,
  NKCODE_MOVE_HOME = 122,
  NKCODE_MOVE_END = 123,
  NKCODE_INSERT = 124,
  NKCODE_FORWARD = 125,
  NKCODE_MEDIA_PLAY = 126,
  NKCODE_MEDIA_PAUSE = 127,
  NKCODE_MEDIA_CLOSE = 128,
  NKCODE_MEDIA_EJECT = 129,
  NKCODE_MEDIA_RECORD = 130,
  NKCODE_F1 = 131,
  NKCODE_F2 = 132,
  NKCODE_F3 = 133,
  NKCODE_F4 = 134,
  NKCODE_F5 = 135,
  NKCODE_F6 = 136,
  NKCODE_F7 = 137,
  NKCODE_F8 = 138,
  NKCODE_F9 = 139,
  NKCODE_F10 = 140,
  NKCODE_F11 = 141,
  NKCODE_F12 = 142,
  NKCODE_NUM_LOCK = 143,
  NKCODE_NUMPAD_0 = 144,
  NKCODE_NUMPAD_1 = 145,
  NKCODE_NUMPAD_2 = 146,
  NKCODE_NUMPAD_3 = 147,
  NKCODE_NUMPAD_4 = 148,
  NKCODE_NUMPAD_5 = 149,
  NKCODE_NUMPAD_6 = 150,
  NKCODE_NUMPAD_7 = 151,
  NKCODE_NUMPAD_8 = 152,
  NKCODE_NUMPAD_9 = 153,
  NKCODE_NUMPAD_DIVIDE = 154,
  NKCODE_NUMPAD_MULTIPLY = 155,
  NKCODE_NUMPAD_SUBTRACT = 156,
  NKCODE_NUMPAD_ADD = 157,
  NKCODE_NUMPAD_DOT = 158,
  NKCODE_NUMPAD_COMMA = 159,
  NKCODE_NUMPAD_ENTER = 160,
  NKCODE_NUMPAD_EQUALS = 161,
  NKCODE_NUMPAD_LEFT_PAREN = 162,
  NKCODE_NUMPAD_RIGHT_PAREN = 163,
  NKCODE_VOLUME_MUTE = 164,
  NKCODE_INFO = 165,
  NKCODE_CHANNEL_UP = 166,
  NKCODE_CHANNEL_DOWN = 167,
  NKCODE_ZOOM_IN = 168,
  NKCODE_ZOOM_OUT = 169,
  NKCODE_TV = 170,
  NKCODE_WINDOW = 171,
  NKCODE_GUIDE = 172,
  NKCODE_DVR = 173,
  NKCODE_BOOKMARK = 174,
  NKCODE_CAPTIONS = 175,
  NKCODE_SETTINGS = 176,
  NKCODE_TV_POWER = 177,
  NKCODE_TV_INPUT = 178,
  NKCODE_STB_POWER = 179,
  NKCODE_STB_INPUT = 180,
  NKCODE_AVR_POWER = 181,
  NKCODE_AVR_INPUT = 182,
  NKCODE_PROG_RED = 183,
  NKCODE_PROG_GREEN = 184,
  NKCODE_PROG_YELLOW = 185,
  NKCODE_PROG_BLUE = 186,
  NKCODE_APP_SWITCH = 187,
  NKCODE_BUTTON_1 = 188,
  NKCODE_BUTTON_2 = 189,
  NKCODE_BUTTON_3 = 190,
  NKCODE_BUTTON_4 = 191,
  NKCODE_BUTTON_5 = 192,
  NKCODE_BUTTON_6 = 193,
  NKCODE_BUTTON_7 = 194,
  NKCODE_BUTTON_8 = 195,
  NKCODE_BUTTON_9 = 196,
  NKCODE_BUTTON_10 = 197,
  NKCODE_BUTTON_11 = 198,
  NKCODE_BUTTON_12 = 199,
  NKCODE_BUTTON_13 = 200,
  NKCODE_BUTTON_14 = 201,
  NKCODE_BUTTON_15 = 202,
  NKCODE_BUTTON_16 = 203,
  NKCODE_LANGUAGE_SWITCH = 204,
  NKCODE_MANNER_MODE = 205,
  NKCODE_3D_MODE = 206,
  NKCODE_CONTACTS = 207,
  NKCODE_CALENDAR = 208,
  NKCODE_MUSIC = 209,
  NKCODE_CALCULATOR = 210,
  NKCODE_ZENKAKU_HANKAKU = 211,
  NKCODE_EISU = 212,
  NKCODE_MUHENKAN = 213,
  NKCODE_HENKAN = 214,
  NKCODE_KATAKANA_HIRAGANA = 215,
  NKCODE_YEN = 216,
  NKCODE_RO = 217,
  NKCODE_KANA = 218,
  NKCODE_ASSIST = 219,

  // Ouya buttons. Just here for reference, they map straight to regular android buttons
  // and will be mapped the same way.
  NKCODE_OUYA_BUTTON_A = 97,
  NKCODE_OUYA_BUTTON_DPAD_DOWN = 20,
  NKCODE_OUYA_BUTTON_DPAD_LEFT = 21,
  NKCODE_OUYA_BUTTON_DPAD_RIGHT = 22,
  NKCODE_OUYA_BUTTON_DPAD_UP = 19,
  NKCODE_OUYA_BUTTON_L1 = 102,
  NKCODE_OUYA_BUTTON_L2 = 104,
  NKCODE_OUYA_BUTTON_L3 = 106,
  NKCODE_OUYA_BUTTON_MENU = 82,
  NKCODE_OUYA_BUTTON_O = 96,
  NKCODE_OUYA_BUTTON_R1 = 103,
  NKCODE_OUYA_BUTTON_R2 = 105,
  NKCODE_OUYA_BUTTON_R3 = 107,
  NKCODE_OUYA_BUTTON_U = 99,
  NKCODE_OUYA_BUTTON_Y = 100,

  // Extended keycodes, not available on Android
  NKCODE_EXT_PIPE = 1001,  // The key next to Z on euro 102-key keyboards.

  NKCODE_EXT_MOUSEBUTTON_1 = 1002,
  NKCODE_EXT_MOUSEBUTTON_2 = 1003,
  NKCODE_EXT_MOUSEBUTTON_3 = 1004,
  NKCODE_EXT_MOUSEWHEEL_UP = 1008,
  NKCODE_EXT_MOUSEWHEEL_DOWN = 1009

    # SDL codes from https://wiki.libsdl.org/SDLKeycodeLookup
    keymap["1073741904"]="left"
    keymap["1073741903"]="right"
    keymap["1073741906"]="up"
    keymap["1073741905"]="down"
    keymap["13"]="enter"
    keymap["1073741912"]="kp_enter"
    keymap["9"]="tab"
    keymap["1073741897"]="insert"
    keymap["127"]="del"
    keymap["1073741901"]="end"
    keymap["1073741898"]="home"
    keymap["1073742053"]="rshift"
    keymap["1073742049"]="shift"
    keymap["1073742048"]="ctrl"
    keymap["1073742050"]="alt"
    keymap["32"]="space"
    keymap["27"]="escape"
    keymap["43"]="add"
    keymap["45"]="subtract"
    keymap["1073741911"]="kp_plus"
    keymap["1073741910"]="kp_minus"
    keymap["1073741882"]="f1"
    keymap["1073741883"]="f2"
    keymap["1073741884"]="f3"
    keymap["1073741885"]="f4"
    keymap["1073741886"]="f5"
    keymap["1073741887"]="f6"
    keymap["1073741888"]="f7"
    keymap["1073741889"]="f8"
    keymap["1073741890"]="f9"
    keymap["1073741891"]="f10"
    keymap["1073741892"]="f11"
    keymap["1073741893"]="f12"
    keymap["48"]="num0"
    keymap["49"]="num1"
    keymap["50"]="num2"
    keymap["51"]="num3"
    keymap["52"]="num4"
    keymap["53"]="num5"
    keymap["54"]="num6"
    keymap["55"]="num7"
    keymap["56"]="num8"
    keymap["57"]="num9"
    keymap["1073741899"]="pageup"
    keymap["1073741902"]="pagedown"
    keymap["1073741922"]="keypad0"
    keymap["1073741913"]="keypad1"
    keymap["1073741914"]="keypad2"
    keymap["1073741915"]="keypad3"
    keymap["1073741916"]="keypad4"
    keymap["1073741917"]="keypad5"
    keymap["1073741918"]="keypad6"
    keymap["1073741919"]="keypad7"
    keymap["1073741920"]="keypad8"
    keymap["1073741921"]="keypad9"
    keymap["46"]="period"
    keymap["1073741881"]="capslock"
    keymap["1073741907"]="numlock"
    keymap["8"]="backspace"
    keymap["42"]="multiply"
    keymap["47"]="divide"
    keymap["1073741894"]="print_screen"
    keymap["1073741895"]="scroll_lock"
    keymap["96"]="backquote"
    keymap["1073741896"]="pause"
    keymap["39"]="quote"
    keymap["44"]="comma"
    keymap["45"]="minus"
    keymap["47"]="slash"
    keymap["59"]="semicolon"
    keymap["61"]="equals"
    keymap["91"]="leftbracket"
    keymap["92"]="backslash"
    keymap["93"]="rightbracket"
    keymap["1073741923"]="kp_period"
    keymap["1073741927"]="kp_equals"
    keymap["1073742052"]="rctrl"
    keymap["1073742054"]="ralt"
    keymap["97"]="a"
    keymap["98"]="b"
    keymap["99"]="c"
    keymap["100"]="d"
    keymap["101"]="e"
    keymap["102"]="f"
    keymap["103"]="g"
    keymap["104"]="h"
    keymap["105"]="i"
    keymap["106"]="j"
    keymap["107"]="k"
    keymap["108"]="l"
    keymap["109"]="m"
    keymap["110"]="n"
    keymap["111"]="o"
    keymap["112"]="p"
    keymap["113"]="q"
    keymap["114"]="r"
    keymap["115"]="s"
    keymap["116"]="t"
    keymap["117"]="u"
    keymap["118"]="v"
    keymap["119"]="w"
    keymap["120"]="x"
    keymap["121"]="y"
    keymap["122"]="z"

    name:keyboard0,type:controller,deadzone:12,crosshair:1
}

function map_retroarch_joystick() {
    local input_name="$1"
    local input_type="$2"
    local input_id="$3"
    local input_value="$4"

    local keys
    case "$input_name" in
        up)
            keys=("dpad_up")
            ;;
        down)
            keys=("dpad_down")
            ;;
        left)
            keys=("dpad_left")
            ;;
        right)
            keys=("dpad_right")
            ;;
        a|b|x|y)
            keys=("$input_name")
            ;;
        leftbottom|leftshoulder)
            keys=("ltrig" "input_load_state")
            ;;
        rightbottom|rightshoulder)
            keys=("input_r" "input_save_state")
            ;;
        lefttop|lefttrigger)
            keys=("input_l2")
            ;;
        righttop|righttrigger)
            keys=("input_r2")
            ;;
        leftthumb)
            keys=("input_l3")
            ;;
        rightthumb)
            keys=("input_r3")
            ;;
        start)
            keys=("input_start" "input_exit_emulator")
            ;;
        select)
            keys=("input_select")
            ;;
        leftanalogleft)
            keys=("ljoy_left")
            ;;
        leftanalogright)
            keys=("ljoy_right")
            ;;
        leftanalogup)
            keys=("ljoy_up")
            ;;
        leftanalogdown)
            keys=("ljoy_down")
            ;;
        rightanalogleft)
            keys=("input_r_x_minus")
            ;;
        rightanalogright)
            keys=("input_r_x_plus")
            ;;
        rightanalogup)
            keys=("input_r_y_minus")
            ;;
        rightanalogdown)
            keys=("input_r_y_plus")
            ;;
        hotkeyenable)
            keys=("input_enable_hotkey")
            _retroarch_select_hotkey=0
            if [[ "$input_type" == "key" && "$input_id" == "0" ]]; then
                return
            fi
            ;;
        *)
            return
            ;;
    esac

    local key
    local value
    local type
    for key in "${keys[@]}"; do
        case "$input_type" in
            hat)
                type="btn"
                value="h$input_id$input_name"
                ;;
            axis)
                type="axis"
                if [[ "$input_value" == "1" ]]; then
                    value="+$input_id"
                else
                    value="-$input_id"
                fi
                ;;
            *)
                type="btn"
                value="$input_id"
                ;;
        esac
        if [[ "$input_name" == "select" && "$_retroarch_select_hotkey" -eq 1 ]]; then
            _retroarch_select_type="$type"
        fi
        key+="_$type"
        iniSet "$key" "$value"
    done
}

function map_redream_keyboard() {
    local input_name="$1"
    local input_type="$2"
    local input_id="$3"
    local input_value="$4"

    local key
    case "$input_name" in
        up)
            keys=("input_player1_up")
            ;;
        down)
            keys=("input_player1_down")
            ;;
        left)
            keys=("input_player1_left" "input_state_slot_decrease")
            ;;
        right)
            keys=("input_player1_right" "input_state_slot_increase")
            ;;
        a)
            keys=("input_player1_a")
            ;;
        b)
            keys=("input_player1_b" "input_reset")
            ;;
        x)
            keys=("input_player1_x" "input_menu_toggle")
            ;;
        y)
            keys=("input_player1_y")
            ;;
        leftbottom|leftshoulder)
            keys=("input_player1_l")
            ;;
        rightbottom|rightshoulder)
            keys=("input_player1_r")
            ;;
        lefttop|lefttrigger)
            keys=("input_player1_l2")
            ;;
        righttop|righttrigger)
            keys=("input_player1_r2")
            ;;
        leftthumb)
            keys=("input_player1_l3")
            ;;
        rightthumb)
            keys=("input_player1_r3")
            ;;
        start)
            keys=("input_player1_start" "input_exit_emulator")
            ;;
        select)
            keys=("input_player1_select")
            ;;
        hotkeyenable)
            keys=("input_enable_hotkey")
            _retroarch_select_hotkey=0
            ;;
        *)
            return
            ;;
    esac

    for key in "${keys[@]}"; do
        iniSet "$key" "${keymap[$input_id]}"
    done

    /opt/retropie/configs/psp/PSP/SYSTEM/controls.ini
}

function onend_redream_joystick() {
    mv "/tmp/tempconfig.cfg" "$dir/$file"

  public static final int DEVICE_ID_DEFAULT = 0;
  public static final int DEVICE_ID_KEYBOARD = 1;
  public static final int DEVICE_ID_MOUSE = 2;
  public static final int DEVICE_ID_PAD_0 = 10;
}

function onend_redream_keyboard() {

  public static final int DEVICE_ID_DEFAULT = 0;
  public static final int DEVICE_ID_KEYBOARD = 1;
  public static final int DEVICE_ID_MOUSE = 2;
  public static final int DEVICE_ID_PAD_0 = 10;
}
