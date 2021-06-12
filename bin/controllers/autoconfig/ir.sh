#!/usr/bin/env bash

# Path to the ir configuration where controls are defined
ir_config_path="$configdir/rc_keymap.cfg"

function check_ir() {
    [[ ! -f "$ir_config_path" ]] && return 1
    return 0
}

function onstart_ir_keyboard() {
    iniConfig '=' '' "$ir_config_path"

    # Get the location of the source keymap file used for defining mappings
    iniGet 'source_keymap_path'
    local source_keymap_path=$ini_value

    # Get the location of the target keymap file that wiil have the mappings
    iniGet 'target_keymap_path'
    declare -g target_keymap_path=$ini_value

    # Create a temp keymap file that has no scan codes
    sed -n '/\[protocols.scancodes\]/q;p' "$source_keymap_path" > '/tmp/rc_keymap.toml'
    echo '[protocols.scancodes]' >> '/tmp/rc_keymap.toml'
    iniConfig ' = ' '' '/tmp/rc_keymap.toml'

    # Inverse the mappings from the keymap file
    declare -Ag scanmap
    while read scancode keyname; do
        scanmap["$keyname"]="${scanmap["$keyname"]},$scancode"
    done < <(grep "0x" "$source_keymap_path" | sed 's/["=]//g')

    # SDL codes from https://wiki.libsdl.org/SDLKeycodeLookup
    keymap['8']='KEY_BACKSPACE'
    keymap['9']='KEY_TAB'
    keymap['13']='KEY_ENTER'
    keymap['27']='KEY_ESC'
    keymap['32']='KEY_SPACE'
    keymap['39']='KEY_APOSTROPHE'
    keymap['42']='KEY_APOSTROPHE'
    keymap['43']='KEY_KPPLUS'
    keymap['44']='KEY_COMMA'
    keymap['45']='KEY_MINUS'
    keymap['46']='KEY_DOT'
    keymap['47']='KEY_SLASH'
    keymap['48']='KEY_0'
    keymap['49']='KEY_1'
    keymap['50']='KEY_2'
    keymap['51']='KEY_3'
    keymap['52']='KEY_4'
    keymap['53']='KEY_5'
    keymap['54']='KEY_6'
    keymap['55']='KEY_7'
    keymap['56']='KEY_8'
    keymap['57']='KEY_9'
    keymap['59']='KEY_SEMICOLON'
    keymap['61']='KEY_EQUAL'
    keymap['91']='KEY_LEFTBRACE'
    keymap['92']='KEY_BACKSLASH'
    keymap['93']='KEY_RIGHTBRACE'
    keymap['96']='KEY_GRAVE'
    keymap['97']='KEY_A'
    keymap['98']='KEY_B'
    keymap['99']='KEY_C'
    keymap['100']='KEY_D'
    keymap['101']='KEY_E'
    keymap['102']='KEY_F'
    keymap['103']='KEY_G'
    keymap['104']='KEY_H'
    keymap['105']='KEY_I'
    keymap['106']='KEY_J'
    keymap['107']='KEY_K'
    keymap['108']='KEY_L'
    keymap['109']='KEY_M'
    keymap['110']='KEY_N'
    keymap['111']='KEY_O'
    keymap['112']='KEY_P'
    keymap['113']='KEY_Q'
    keymap['114']='KEY_R'
    keymap['115']='KEY_S'
    keymap['116']='KEY_T'
    keymap['117']='KEY_U'
    keymap['118']='KEY_V'
    keymap['119']='KEY_W'
    keymap['120']='KEY_X'
    keymap['121']='KEY_Y'
    keymap['122']='KEY_Z'
    keymap['127']='KEY_DELETE'
    keymap['1073741881']='KEY_CAPSLOCK'
    keymap['1073741882']='KEY_F1'
    keymap['1073741883']='KEY_F2'
    keymap['1073741884']='KEY_F3'
    keymap['1073741885']='KEY_F4'
    keymap['1073741886']='KEY_F5'
    keymap['1073741887']='KEY_F6'
    keymap['1073741888']='KEY_F7'
    keymap['1073741889']='KEY_F8'
    keymap['1073741890']='KEY_F9'
    keymap['1073741891']='KEY_F10'
    keymap['1073741892']='KEY_F11'
    keymap['1073741893']='KEY_F12'
    keymap['1073741894']='KEY_PRINT'
    keymap['1073741895']='KEY_SCROLLLOCK'
    keymap['1073741897']='KEY_INSERT'
    keymap['1073741898']='KEY_HOME'
    keymap['1073741899']='KEY_PAGEUP'
    keymap['1073741901']='KEY_END'
    keymap['1073741902']='KEY_PAGEDOWN'
    keymap['1073741903']='KEY_RIGHT'
    keymap['1073741904']='KEY_LEFT'
    keymap['1073741905']='KEY_DOWN'
    keymap['1073741906']='KEY_UP'
    keymap['1073741907']='KEY_NUMLOCK'
    keymap['1073741908']='KEY_KPSLASH'
    keymap['1073741909']='KEY_KPASTERISK'
    keymap['1073741910']='KEY_KPMINUS'
    keymap['1073741911']='KEY_KPPLUS'
    keymap['1073741912']='KEY_KPENTER'
    keymap['1073741913']='KEY_NUMERIC_1'
    keymap['1073741914']='KEY_NUMERIC_2'
    keymap['1073741915']='KEY_NUMERIC_3'
    keymap['1073741916']='KEY_NUMERIC_4'
    keymap['1073741917']='KEY_NUMERIC_5'
    keymap['1073741918']='KEY_NUMERIC_6'
    keymap['1073741919']='KEY_NUMERIC_7'
    keymap['1073741920']='KEY_NUMERIC_8'
    keymap['1073741921']='KEY_NUMERIC_9'
    keymap['1073741922']='KEY_NUMERIC_0'
    keymap['1073741923']='KEY_KPDOT'
    keymap['1073741927']='KEY_KPEQUAL'
    keymap['1073742048']='KEY_LEFTCTRL'
    keymap['1073742049']='KEY_LEFTSHIFT'
    keymap['1073742050']='KEY_LEFTALT'
    keymap['1073742052']='KEY_RIGHTCTRL'
    keymap['1073742053']='KEY_RIGHTSHIFT'
    keymap['1073742054']='KEY_RIGHTALT'

    # Define initial values
    declare -A defaults
    defaults['KEY_ESC']='KEY_CLEAR,KEY_EXIT'

    for input_key in "${!defaults[@]}"; do
        local keys=${defaults["$input_key"]}

        for key in ${keys//,/ }; do
            # Find the corresponding scancodes
            local scancodes=${scanmap["$key"]}
            if [ -z "$scancodes" ]; then
                continue
            fi

            # Map each scan code to the corresponding key
            for scancode in ${scancodes//,/ }; do
                if [ -n "$scancode" ]; then
                    iniSet "$scancode" "\"$input_key\" # Original: $key"
                fi
            done
        done
    done
}

function map_ir_keyboard() {
    local input_name=$1
    local input_type=$2
    local input_id=$3
    local input_value=$4

    # Find the corresponding key name for the given sdl id
    local input_key=${keymap["$input_id"]}
    if [ -z "$input_key" ]; then
        return
    fi

    # Look up the ir key this input maps to
    local keys
    case "$input_name" in
        up)
            keys=('KEY_UP')
            ;;
        down)
            keys=('KEY_DOWN')
            ;;
        left)
            keys=('KEY_LEFT')
            ;;
        right)
            keys=('KEY_RIGHT')
            ;;
        a)
            keys=('KEY_A' 'KEY_1' 'KEY_NUMERIC_1' 'KEY_RED' 'KEY_SELECT')
            ;;
        b)
            keys=('KEY_B' 'KEY_2' 'KEY_NUMERIC_2' 'KEY_GREEN' 'KEY_CANCEL' 'KEY_PREVIOUS')
            ;;
        x)
            keys=('KEY_C' 'KEY_3' 'KEY_NUMERIC_3' 'KEY_YELLOW')
            ;;
        y)
            keys=('KEY_D' 'KEY_4' 'KEY_NUMERIC_4' 'KEY_BLUE')
            ;;
        leftbottom|leftshoulder)
            keys=('KEY_PAGEUP' 'KEY_SCROLLUP' 'KEY_CHANNELUP')
            ;;
        rightbottom|rightshoulder)
            keys=('KEY_PAGEDOWN' 'KEY_SCROLLDOWN' 'KEY_CHANNELDOWN')
            ;;
        start)
            keys=('KEY_ENTER' 'KEY_OK')
            ;;
        select)
            keys=('KEY_MENU' 'KEY_INFO')
            ;;
        *)
            ;;
    esac

    for key in "${keys[@]}"; do
        # Find the corresponding scancodes
        local scancodes=${scanmap["$key"]}
        if [ -z "$scancodes" ]; then
            continue
        fi

        # Map each scan code to the corresponding key
        for scancode in ${scancodes//,/ }; do
            if [ -n "$scancode" ]; then
                iniSet "$scancode" "\"$input_key\" # Original: $key"
            fi
        done
    done
}

function onend_ir_keyboard() {
    sudo mv '/tmp/rc_keymap.toml' "$target_keymap_path"
}
