#!/usr/bin/env bash

# Path to the advmame configuration where controls are defined
ppsspp_config_file="$configdir/psp/PSP/SYSTEM/controls.ini"
sdldb_file="$rootdir/emulators/ppsspp/assets/gamecontrollerdb.txt"

function check_ppsspp() {
    [[ ! -d "$rootdir/emulators/ppsspp" ]] && return 1
    return 0
}

function onstart_ppsspp() {
    local controller=$1

    if [ -f "$ppsspp_config_file" ]; then
        cp "$ppsspp_config_file" '/tmp/ppsspp-controls.ini'
    else
        echo '[ControlMapping]' > '/tmp/ppsspp-controls.ini'
    fi
    _set_ppsspp_ini '/tmp/ppsspp-controls.ini'

    # Reset inputs for this controller
    local regex="$controller-[0-9]\+"
    sed -i "/^.\+ = $regex\$/d" '/tmp/ppsspp-controls.ini'
    sed -i "s/,$regex//g" '/tmp/ppsspp-controls.ini'
    sed -i "s/ $regex,/ /g" '/tmp/ppsspp-controls.ini'
}

function _set_ppsspp_ini() {
    iniConfig ' = ' '' "$1"
}

function onstart_ppsspp_joystick() {
    onstart_ppsspp '10'

    # SDL codes from https://github.com/hrydgard/ppsspp/blob/6f795fc12043599fcb55b6d7d385e75fe2e525dc/SDL/SDLJoystick.cpp#L108-L144
    # Button codes from:
    # * https://github.com/hrydgard/ppsspp/blob/6f795fc12043599fcb55b6d7d385e75fe2e525dc/Core/KeyMap.cpp#L236-L247
    # * https://github.com/hrydgard/ppsspp/blob/0c40e918c92b897f745abee0d09cf033a1572337/Common/Input/KeyCodes.h
    declare -Ag ppsspp_sdl_button_map
    ppsspp_sdl_button_map['dpup']='19' # NKCODE_DPAD_UP
    ppsspp_sdl_button_map['dpdown']='20' # NKCODE_DPAD_DOWN
    ppsspp_sdl_button_map['dpleft']='21' # NKCODE_DPAD_LEFT
    ppsspp_sdl_button_map['dpright']='22' # NKCODE_DPAD_RIGHT
    ppsspp_sdl_button_map['a']='189' # NKCODE_BUTTON_2
    ppsspp_sdl_button_map['b']='190' # NKCODE_BUTTON_3
    ppsspp_sdl_button_map['x']='191' # NKCODE_BUTTON_4
    ppsspp_sdl_button_map['y']='188' # NKCODE_BUTTON_1
    ppsspp_sdl_button_map['rightshoulder']='192' # NKCODE_BUTTON_5
    ppsspp_sdl_button_map['leftshoulder']='193' # NKCODE_BUTTON_6
    ppsspp_sdl_button_map['start']='197' # NKCODE_BUTTON_10
    ppsspp_sdl_button_map['back']='196' # NKCODE_BUTTON_9
    ppsspp_sdl_button_map['guide']='4' # NKCODE_BACK
    ppsspp_sdl_button_map['leftstick']='106' # NKCODE_BUTTON_THUMBL
    ppsspp_sdl_button_map['rightstick']='107' # NKCODE_BUTTON_THUMBR

    # Define initial device-specific config
    truncate -s0 /tmp/ppsspp-device-controls.ini
}

function onstart_ppsspp_keyboard() {
    onstart_ppsspp '1'

    # SDL codes from https://wiki.libsdl.org/SDLKeycodeLookup
    declare -Ag ppsspp_keymap
    ppsspp_keymap['8']='67' # NKCODE_DEL
    ppsspp_keymap['9']='61' # NKCODE_TAB
    ppsspp_keymap['13']='66' # NKCODE_ENTER
    ppsspp_keymap['27']='111' # NKCODE_ESCAPE
    ppsspp_keymap['32']='62' # NKCODE_SPACE
    ppsspp_keymap['39']='75' # NKCODE_APOSTROPHE
    ppsspp_keymap['42']='155' # NKCODE_NUMPAD_MULTIPLY
    ppsspp_keymap['43']='157' # NKCODE_NUMPAD_ADD
    ppsspp_keymap['44']='155' # NKCODE_COMMA
    ppsspp_keymap['45']='69' # NKCODE_MINUS
    ppsspp_keymap['45']='156' # NKCODE_NUMPAD_SUBTRACT
    ppsspp_keymap['46']='56' # NKCODE_PERIOD
    ppsspp_keymap['47']='154' # NKCODE_PERIOD
    ppsspp_keymap['47']='76' # NKCODE_SLASH
    ppsspp_keymap['48']='7' # NKCODE_0
    ppsspp_keymap['49']='8' # NKCODE_1
    ppsspp_keymap['50']='9' # NKCODE_2
    ppsspp_keymap['51']='10' # NKCODE_3
    ppsspp_keymap['52']='11' # NKCODE_4
    ppsspp_keymap['53']='12' # NKCODE_5
    ppsspp_keymap['54']='13' # NKCODE_6
    ppsspp_keymap['55']='14' # NKCODE_7
    ppsspp_keymap['56']='15' # NKCODE_8
    ppsspp_keymap['57']='16' # NKCODE_9
    ppsspp_keymap['59']='74' # NKCODE_SEMICOLON
    ppsspp_keymap['61']='70' # NKCODE_EQUALS
    ppsspp_keymap['91']='71' # NKCODE_LEFT_BRACKET
    ppsspp_keymap['92']='73' # NKCODE_BACKSLASH
    ppsspp_keymap['93']='72' # NKCODE_RIGHT_BRACKET
    ppsspp_keymap['96']='68' # NKCODE_GRAVE
    ppsspp_keymap['97']='29' # NKCODE_A
    ppsspp_keymap['98']='30' # NKCODE_B
    ppsspp_keymap['99']='31' # NKCODE_C
    ppsspp_keymap['100']='32' # NKCODE_D
    ppsspp_keymap['101']='33' # NKCODE_E
    ppsspp_keymap['102']='34' # NKCODE_F
    ppsspp_keymap['103']='35' # NKCODE_G
    ppsspp_keymap['104']='36' # NKCODE_H
    ppsspp_keymap['105']='37' # NKCODE_I
    ppsspp_keymap['106']='38' # NKCODE_J
    ppsspp_keymap['107']='39' # NKCODE_K
    ppsspp_keymap['108']='40' # NKCODE_L
    ppsspp_keymap['109']='41' # NKCODE_M
    ppsspp_keymap['110']='42' # NKCODE_N
    ppsspp_keymap['111']='43' # NKCODE_O
    ppsspp_keymap['112']='44' # NKCODE_P
    ppsspp_keymap['113']='45' # NKCODE_Q
    ppsspp_keymap['114']='46' # NKCODE_R
    ppsspp_keymap['115']='47' # NKCODE_S
    ppsspp_keymap['116']='48' # NKCODE_T
    ppsspp_keymap['117']='49' # NKCODE_U
    ppsspp_keymap['118']='50' # NKCODE_V
    ppsspp_keymap['119']='51' # NKCODE_W
    ppsspp_keymap['120']='52' # NKCODE_X
    ppsspp_keymap['121']='53' # NKCODE_Y
    ppsspp_keymap['122']='54' # NKCODE_Z
    ppsspp_keymap['127']='112' # NKCODE_FORWARD_DEL
    ppsspp_keymap['1073741881']='115' # NKCODE_CAPS_LOCK
    ppsspp_keymap['1073741882']='131' # NKCODE_F1
    ppsspp_keymap['1073741883']='132' # NKCODE_F2
    ppsspp_keymap['1073741884']='133' # NKCODE_F3
    ppsspp_keymap['1073741885']='134' # NKCODE_F4
    ppsspp_keymap['1073741886']='135' # NKCODE_F5
    ppsspp_keymap['1073741887']='136' # NKCODE_F6
    ppsspp_keymap['1073741888']='137' # NKCODE_F7
    ppsspp_keymap['1073741889']='138' # NKCODE_F8
    ppsspp_keymap['1073741890']='139' # NKCODE_F9
    ppsspp_keymap['1073741891']='140' # NKCODE_F10
    ppsspp_keymap['1073741892']='141' # NKCODE_F11
    ppsspp_keymap['1073741893']='142' # NKCODE_F12
    ppsspp_keymap['1073741894']='120' # NKCODE_SYSRQ
    ppsspp_keymap['1073741895']='116' # NKCODE_SCROLL_LOCK
    ppsspp_keymap['1073741896']='127' # NKCODE_MEDIA_PAUSE
    ppsspp_keymap['1073741897']='124' # NKCODE_INSERT
    ppsspp_keymap['1073741898']='122' # NKCODE_MOVE_HOME
    ppsspp_keymap['1073741899']='92' # NKCODE_PAGE_UP
    ppsspp_keymap['1073741901']='123' # NKCODE_MOVE_END
    ppsspp_keymap['1073741902']='93' # NKCODE_PAGE_DOWN
    ppsspp_keymap['1073741903']='22' # NKCODE_DPAD_RIGHT
    ppsspp_keymap['1073741904']='21' # NKCODE_DPAD_LEFT
    ppsspp_keymap['1073741905']='20' # NKCODE_DPAD_DOWN
    ppsspp_keymap['1073741906']='19' # NKCODE_DPAD_UP
    ppsspp_keymap['1073741907']='143' # NKCODE_NUM_LOCK
    ppsspp_keymap['1073741910']='156' # NKCODE_NUMPAD_SUBTRACT
    ppsspp_keymap['1073741911']='157' # NKCODE_NUMPAD_ADD
    ppsspp_keymap['1073741912']='160' # NKCODE_NUMPAD_ENTER
    ppsspp_keymap['1073741913']='145' # NKCODE_NUMPAD_1
    ppsspp_keymap['1073741914']='146' # NKCODE_NUMPAD_2
    ppsspp_keymap['1073741915']='147' # NKCODE_NUMPAD_3
    ppsspp_keymap['1073741916']='148' # NKCODE_NUMPAD_4
    ppsspp_keymap['1073741917']='149' # NKCODE_NUMPAD_5
    ppsspp_keymap['1073741918']='150' # NKCODE_NUMPAD_6
    ppsspp_keymap['1073741919']='151' # NKCODE_NUMPAD_7
    ppsspp_keymap['1073741920']='152' # NKCODE_NUMPAD_8
    ppsspp_keymap['1073741921']='153' # NKCODE_NUMPAD_9
    ppsspp_keymap['1073741922']='144' # NKCODE_NUMPAD_0
    ppsspp_keymap['1073741923']='158' # NKCODE_NUMPAD_DOT
    ppsspp_keymap['1073741927']='161' # NKCODE_NUMPAD_EQUALS
    ppsspp_keymap['1073742048']='113' # NKCODE_CTRL_LEFT
    ppsspp_keymap['1073742049']='59' # NKCODE_SHIFT_LEFT
    ppsspp_keymap['1073742050']='57' # NKCODE_ALT_LEFT
    ppsspp_keymap['1073742052']='114' # NKCODE_CTRL_RIGHT
    ppsspp_keymap['1073742053']='60' # NKCODE_SHIFT_RIGHT
    ppsspp_keymap['1073742054']='58' # NKCODE_ALT_RIGHT

    map_ppsspp 'Pause' '1' '111'
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
            key='Pause'
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
            local sdl_button_name=$(grep -E "^$DEVICE_GUID," "$sdldb_file" | grep -oE "[^,]+:h$input_id.$input_value," | cut -d ':' -f 1 | tail -n 1)
            if [ -z "$sdl_button_name" ]; then
                return
            fi

            value=${ppsspp_sdl_button_map["$sdl_button_name"]}
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
            local sdl_button_name=$(grep -E "^$DEVICE_GUID," "$sdldb_file" | grep -oE "[^,]+:b$input_id," | cut -d ':' -f 1 | tail -n 1)
            if [ -z "$sdl_button_name" ]; then
                return
            fi

            value=${ppsspp_sdl_button_map["$sdl_button_name"]}
            ;;
    esac

    if [ -n "$value" ]; then
        _set_ppsspp_ini /tmp/ppsspp-controls.ini
        map_ppsspp "$key" '10' "$value"

        # Device-specific config
        _set_ppsspp_ini /tmp/ppsspp-device-controls.ini
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
    local value=${ppsspp_keymap[$input_id]}

    if [ -n "$value" ]; then
        map_ppsspp "$key" '1' "$value"
    fi
}

function _onend_ppsspp() {
    mkdir -p "$(dirname "$ppsspp_config_file")"
    mv '/tmp/ppsspp-controls.ini' "$ppsspp_config_file"
}

function onend_ppsspp_joystick() {
    _onend_ppsspp

    # Define a device-specific file in order to support multiple joysticks
    local ppsspp_device_config_file="$configdir/psp/PSP/SYSTEM/controls-${DEVICE_NAME//[:><?\"\/\\|*]/}.ini"
    cp '/tmp/ppsspp-device-controls.ini' "$ppsspp_device_config_file"
}

function onend_ppsspp_keyboard() {
    _onend_ppsspp
}
