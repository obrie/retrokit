#!/usr/bin/env bash

# Path to the advmame configuration where controls are defined
ppsspp_config_path="$configdir/psp/PSP/SYSTEM/controls.ini"
sdldb_path="$rootdir/emulators/ppsspp/assets/gamecontrollerdb.txt"

function check_ppsspp() {
    [[ ! -d "$rootdir/emulators/ppsspp" ]] && return 1
    return 0
}

function onstart_ppsspp() {
    local controller=$1

    if [ -f "$ppsspp_config_path" ]; then
        cp "$ppsspp_config_path" '/tmp/ppsspp-controls.ini'
    else
        echo '[ControlMapping]' > '/tmp/ppsspp-controls.ini'
    fi
    iniConfig ' = ' '' '/tmp/ppsspp-controls.ini'

    # Reset inputs for this controller
    local regex="$controller-[0-9]\+"
    sed -i "/^.\+ = $regex\$/d" '/tmp/ppsspp-controls.ini'
    sed -i "s/,$regex//g" '/tmp/ppsspp-controls.ini'
    sed -i "s/ $regex,/ /g" '/tmp/ppsspp-controls.ini'
}

function onstart_ppsspp_joystick() {
    onstart_ppsspp '10'

    # SDL codes from https://github.com/hrydgard/ppsspp/blob/6f795fc12043599fcb55b6d7d385e75fe2e525dc/SDL/SDLJoystick.cpp#L108-L144
    # Button codes from:
    # * https://github.com/hrydgard/ppsspp/blob/6f795fc12043599fcb55b6d7d385e75fe2e525dc/Core/KeyMap.cpp#L236-L247
    # * https://github.com/hrydgard/ppsspp/blob/0c40e918c92b897f745abee0d09cf033a1572337/Common/Input/KeyCodes.h
    declare -Ag sdl_button_map
    sdl_button_map['dpup']='19' # NKCODE_DPAD_UP
    sdl_button_map['dpdown']='20' # NKCODE_DPAD_DOWN
    sdl_button_map['dpleft']='21' # NKCODE_DPAD_LEFT
    sdl_button_map['dpright']='22' # NKCODE_DPAD_RIGHT
    sdl_button_map['a']='189' # NKCODE_BUTTON_2
    sdl_button_map['b']='190' # NKCODE_BUTTON_3
    sdl_button_map['x']='191' # NKCODE_BUTTON_4
    sdl_button_map['y']='188' # NKCODE_BUTTON_1
    sdl_button_map['rightshoulder']='192' # NKCODE_BUTTON_5
    sdl_button_map['leftshoulder']='193' # NKCODE_BUTTON_6
    sdl_button_map['start']='197' # NKCODE_BUTTON_10
    sdl_button_map['back']='196' # NKCODE_BUTTON_9
    sdl_button_map['guide']='4' # NKCODE_BACK
    sdl_button_map['leftstick']='106' # NKCODE_BUTTON_THUMBL
    sdl_button_map['rightstick']='107' # NKCODE_BUTTON_THUMBR
}

function onstart_ppsspp_keyboard() {
    onstart_ppsspp '1'

    # SDL codes from https://wiki.libsdl.org/SDLKeycodeLookup
    declare -Ag keymap
    keymap['8']='67' # NKCODE_DEL
    keymap['9']='61' # NKCODE_TAB
    keymap['13']='66' # NKCODE_ENTER
    keymap['27']='111' # NKCODE_ESCAPE
    keymap['32']='62' # NKCODE_SPACE
    keymap['39']='75' # NKCODE_APOSTROPHE
    keymap['42']='155' # NKCODE_NUMPAD_MULTIPLY
    keymap['43']='157' # NKCODE_NUMPAD_ADD
    keymap['44']='155' # NKCODE_COMMA
    keymap['45']='69' # NKCODE_MINUS
    keymap['45']='156' # NKCODE_NUMPAD_SUBTRACT
    keymap['46']='56' # NKCODE_PERIOD
    keymap['47']='154' # NKCODE_PERIOD
    keymap['47']='76' # NKCODE_SLASH
    keymap['48']='7' # NKCODE_0
    keymap['49']='8' # NKCODE_1
    keymap['50']='9' # NKCODE_2
    keymap['51']='10' # NKCODE_3
    keymap['52']='11' # NKCODE_4
    keymap['53']='12' # NKCODE_5
    keymap['54']='13' # NKCODE_6
    keymap['55']='14' # NKCODE_7
    keymap['56']='15' # NKCODE_8
    keymap['57']='16' # NKCODE_9
    keymap['59']='74' # NKCODE_SEMICOLON
    keymap['61']='70' # NKCODE_EQUALS
    keymap['91']='71' # NKCODE_LEFT_BRACKET
    keymap['92']='73' # NKCODE_BACKSLASH
    keymap['93']='72' # NKCODE_RIGHT_BRACKET
    keymap['96']='68' # NKCODE_GRAVE
    keymap['97']='29' # NKCODE_A
    keymap['98']='30' # NKCODE_B
    keymap['99']='31' # NKCODE_C
    keymap['100']='32' # NKCODE_D
    keymap['101']='33' # NKCODE_E
    keymap['102']='34' # NKCODE_F
    keymap['103']='35' # NKCODE_G
    keymap['104']='36' # NKCODE_H
    keymap['105']='37' # NKCODE_I
    keymap['106']='38' # NKCODE_J
    keymap['107']='39' # NKCODE_K
    keymap['108']='40' # NKCODE_L
    keymap['109']='41' # NKCODE_M
    keymap['110']='42' # NKCODE_N
    keymap['111']='43' # NKCODE_O
    keymap['112']='44' # NKCODE_P
    keymap['113']='45' # NKCODE_Q
    keymap['114']='46' # NKCODE_R
    keymap['115']='47' # NKCODE_S
    keymap['116']='48' # NKCODE_T
    keymap['117']='49' # NKCODE_U
    keymap['118']='50' # NKCODE_V
    keymap['119']='51' # NKCODE_W
    keymap['120']='52' # NKCODE_X
    keymap['121']='53' # NKCODE_Y
    keymap['122']='54' # NKCODE_Z
    keymap['127']='112' # NKCODE_FORWARD_DEL
    keymap['1073741881']='115' # NKCODE_CAPS_LOCK
    keymap['1073741882']='131' # NKCODE_F1
    keymap['1073741883']='132' # NKCODE_F2
    keymap['1073741884']='133' # NKCODE_F3
    keymap['1073741885']='134' # NKCODE_F4
    keymap['1073741886']='135' # NKCODE_F5
    keymap['1073741887']='136' # NKCODE_F6
    keymap['1073741888']='137' # NKCODE_F7
    keymap['1073741889']='138' # NKCODE_F8
    keymap['1073741890']='139' # NKCODE_F9
    keymap['1073741891']='140' # NKCODE_F10
    keymap['1073741892']='141' # NKCODE_F11
    keymap['1073741893']='142' # NKCODE_F12
    keymap['1073741894']='120' # NKCODE_SYSRQ
    keymap['1073741895']='116' # NKCODE_SCROLL_LOCK
    keymap['1073741896']='127' # NKCODE_MEDIA_PAUSE
    keymap['1073741897']='124' # NKCODE_INSERT
    keymap['1073741898']='122' # NKCODE_MOVE_HOME
    keymap['1073741899']='92' # NKCODE_PAGE_UP
    keymap['1073741901']='123' # NKCODE_MOVE_END
    keymap['1073741902']='93' # NKCODE_PAGE_DOWN
    keymap['1073741903']='22' # NKCODE_DPAD_RIGHT
    keymap['1073741904']='21' # NKCODE_DPAD_LEFT
    keymap['1073741905']='20' # NKCODE_DPAD_DOWN
    keymap['1073741906']='19' # NKCODE_DPAD_UP
    keymap['1073741907']='143' # NKCODE_NUM_LOCK
    keymap['1073741910']='156' # NKCODE_NUMPAD_SUBTRACT
    keymap['1073741911']='157' # NKCODE_NUMPAD_ADD
    keymap['1073741912']='160' # NKCODE_NUMPAD_ENTER
    keymap['1073741913']='145' # NKCODE_NUMPAD_1
    keymap['1073741914']='146' # NKCODE_NUMPAD_2
    keymap['1073741915']='147' # NKCODE_NUMPAD_3
    keymap['1073741916']='148' # NKCODE_NUMPAD_4
    keymap['1073741917']='149' # NKCODE_NUMPAD_5
    keymap['1073741918']='150' # NKCODE_NUMPAD_6
    keymap['1073741919']='151' # NKCODE_NUMPAD_7
    keymap['1073741920']='152' # NKCODE_NUMPAD_8
    keymap['1073741921']='153' # NKCODE_NUMPAD_9
    keymap['1073741922']='144' # NKCODE_NUMPAD_0
    keymap['1073741923']='158' # NKCODE_NUMPAD_DOT
    keymap['1073741927']='161' # NKCODE_NUMPAD_EQUALS
    keymap['1073742048']='113' # NKCODE_CTRL_LEFT
    keymap['1073742049']='59' # NKCODE_SHIFT_LEFT
    keymap['1073742050']='57' # NKCODE_ALT_LEFT
    keymap['1073742052']='114' # NKCODE_CTRL_RIGHT
    keymap['1073742053']='60' # NKCODE_SHIFT_RIGHT
    keymap['1073742054']='58' # NKCODE_ALT_RIGHT
}

# Generates the configuration key for a given ES input name
function _get_config_key() {
    local input_name=$1
    local key=''

    case "$input_name" in
        up)
            key='Up'
            ;;
        down)
            key='Down'
            ;;
        left)
            key='Left'
            ;;
        right)
            key='Right'
            ;;
        a)
            key='Circle'
            ;;
        b)
            key='Cross'
            ;;
        x)
            key='Triangle'
            ;;
        y)
            key='Square'
            ;;
        leftbottom|leftshoulder)
            key='L'
            ;;
        rightbottom|rightshoulder)
            key='R'
            ;;
        start)
            key='Start'
            ;;
        select)
            key='Select'
            ;;
        leftanalogleft)
            key='An.Left'
            ;;
        leftanalogright)
            key='An.Right'
            ;;
        leftanalogup)
            key='An.Up'
            ;;
        leftanalogdown)
            key='An.Down'
            ;;
        rightanalogleft)
            key='RightAn.Left'
            ;;
        rightanalogright)
            key='RightAn.Right'
            ;;
        rightanalogup)
            key='RightAn.Up'
            ;;
        rightanalogdown)
            key='RightAn.Down'
            ;;
        leftthumb)
            key='ThumbL'
            ;;
        rightthumb)
            key='ThumbR'
            ;;
        *)
            ;;
    esac

    echo "$key"
}

function map_ppsspp() {
    local key=$1
    local controller=$2
    local value=$3

    iniGet "$key"

    # Merge the mapped value with existing ones
    local merged_value=$(echo "$ini_value" | sed 's/,/\n/g' | grep -Ev "${controller}-" | sed ':a;N;$!ba;s/\n/,/g')
    if [ -n "$merged_value" ]; then
        merged_value+=','
    fi
    merged_value+="${controller}-${value}"

    iniSet "$key" "$merged_value"
}

function map_ppsspp_joystick() {
    local input_name=$1
    local input_type=$2
    local input_id=$3
    local input_value=$4

    # Look up the ppsspp configuration key this input maps to
    local key=$(_get_config_key "$input_name")
    if [ -z "$key" ]; then
        return
    fi

    local value
    case "$input_type" in
        hat)
            # Get the SDL button name that's associated with this HAT direction
            local sdl_button_name=$(grep -E "^$DEVICE_GUID," "$sdldb_path" | grep -oE "[^,]+:h$input_id.$input_value," | cut -d ':' -f 1)
            if [ -z "$sdl_button_name" ]; then
                return
            fi

            value=${sdl_button_map["$sdl_button_name"]}
            ;;
        axis)
            # Translate logic from https://github.com/hrydgard/ppsspp/blob/6f795fc12043599fcb55b6d7d385e75fe2e525dc/Core/KeyMap.cpp#L782-L785
            local direction
            if [[ "$input_value" == '1' ]]; then
                direction='0'
            else
                direction='1'
            fi

            value=$((4000 + $input_id * 2 + $direction))
            ;;
        *)
            # Get the SDL button name that's associated with this button id
            local sdl_button_name=$(grep -E "^$DEVICE_GUID," "$sdldb_path" | grep -oE "[^,]+:b$input_id," | cut -d ':' -f 1)
            if [ -z "$sdl_button_name" ]; then
                return
            fi

            value=${sdl_button_map["$sdl_button_name"]}
            ;;
    esac

    if [ -n "$value" ]; then
        map_ppsspp "$key" '10' "$value"
    fi
}

function map_ppsspp_keyboard() {
    local input_name=$1
    local input_type=$2
    local input_id=$3
    local input_value=$4

    # Look up the ppsspp configuration key this input maps to
    local key=$(_get_config_key "$input_name" 1)
    if [ -z "$key" ]; then
        return
    fi

    # Find the corresponding advmame key name for the given sdl id
    local value=${keymap[$input_id]}

    if [ -n "$value" ]; then
        map_ppsspp "$key" '1' "$value"
    fi
}

function _onend_ppsspp() {
    mkdir -p "$(dirname "$ppsspp_config_path")"
    mv '/tmp/ppsspp-controls.ini' "$ppsspp_config_path"
}

function onend_ppsspp_joystick() {
    _onend_ppsspp
}

function onend_ppsspp_keyboard() {
    _onend_ppsspp
}
