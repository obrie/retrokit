#!/usr/bin/env bash

# Path to the advmame configuration where controls are defined
advmame_config_path="$configdir/mame-advmame/advmame.rc"

# Maximum number of players to configure for each controller
max_players=4

# Generates the input_map configuration key to use for a given player
# number.
function _get_player_key() {
    local input_name=$1
    local player=$2
    local key=''

    case "$input_name" in
        up|down|left|right)
            key="p${player}_${input_name}"
            ;;
        a)
            key="p${player}_button1"
            ;;
        b)
            key="p${player}_button2"
            ;;
        x)
            key="p${player}_button3"
            ;;
        y)
            key="p${player}_button4"
            ;;
        start)
            key="start$player"
            ;;
        leftbottom|leftshoulder)
            key="p${player}_button6"
            ;;
        rightbottom|rightshoulder)
            key="p${player}_button5"
            ;;
        lefttop|lefttrigger)
            key="p${player}_button8"
            ;;
        righttop|righttrigger)
            key="p${player}_button7"
            ;;
        select)
            key="coin$player"
            ;;
        leftanalogleft)
            key="p${player}_doubleleft_left"
            ;;
        leftanalogright)
            key="p${player}_doubleleft_right"
            ;;
        leftanalogup)
            key="p${player}_doubleleft_up"
            ;;
        leftanalogdown)
            key="p${player}_doubleleft_down"
            ;;
        rightanalogleft)
            key="p${player}_doubleright_left"
            ;;
        rightanalogright)
            key="p${player}_doubleright_right"
            ;;
        rightanalogup)
            key="p${player}_doubleright_up"
            ;;
        rightanalogdown)
            key="p${player}_doubleright_down"
            ;;
        hotkeyenable)
            # This key name is only used by us to internally identify the hotkey.
            # It is not used by advmame.
            key='hotkey'
            ;;
        *)
            ;;
    esac

    echo "$key"
}

# Generates the input_map configuration key to use for the advmame UI
function _get_ui_key() {
    local input_name=$1
    local key=''

    case "$input_name" in
        up|down|left|right)
            key="ui_$input_name"
            ;;
        a)
            key='ui_select'
            ;;
        *)
            ;;
    esac

    echo "$key"
}

# Generates the input_map configuration key to use for the advmame UI
function _get_hotkey() {
    local input_name=$1
    local key=''

    case "$input_name" in
        b)
            key="ui_reset_machine"
            ;;
        x)
            key="ui_configure"
            ;;
        y)
            key="ui_pause"
            ;;
        start)
            key="ui_cancel"
            ;;
        *)
            ;;
    esac

    echo "$key"
}

function _onstart_advmame() {
    local controller=$1

    cp "$advmame_config_path" '/tmp/advmame.rc'
    iniConfig ' ' '' '/tmp/advmame.rc'

    # Reset inputs for this controller
    local regex
    if [ "$controller" == 'keyboard' ]; then
        regex="keyboard\[[^]]\+\]"
    else
        regex="\(joystick_button\|joystick_digital\)\[$controller[^]]\+\]"
    fi
    sudo sed -i "/^input_map\[[^]]\+\] $regex\$/d" '/tmp/advmame.rc'
    sudo sed -i "s/ or $regex\|$regex or//g" '/tmp/advmame.rc'

    declare -Ag mapped_inputs
    declare -g hotkey_value
}

function onstart_advmame_joystick() {
    # Identify controller by its vendor+product by parsing the data from the
    # SDL-specific GUID.
    # 
    # See: https://github.com/libsdl-org/SDL/blob/804e5799ad2b596312b046b1701d1684d3df2fe1/src/joystick/linux/SDL_sysjoystick.c#L125-L130
    local vendor_id_hex="${DEVICE_GUID:10:2}${DEVICE_GUID:8:2}"
    local product_id_hex="${DEVICE_GUID:18:2}${DEVICE_GUID:16:2}"
    declare -g controller_guid="${vendor_id_hex}_${product_id_hex}"

    _onstart_advmame "$controller_guid"
}

function onstart_advmame_keyboard() {
    _onstart_advmame 'keyboard'

    declare -Ag keymap

    # SDL codes from https://wiki.libsdl.org/SDLKeycodeLookup
    keymap['8']='backspace'
    keymap['9']='tab'
    keymap['13']='enter'
    keymap['27']='esc'
    keymap['32']='space'
    keymap['39']='quote'
    keymap['42']='asterisk_pad'
    keymap['43']='plus_pad'
    keymap['44']='comma'
    keymap['45']='minus'
    keymap['46']='period'
    keymap['47']='slash'
    keymap['48']='0'
    keymap['49']='1'
    keymap['50']='2'
    keymap['51']='3'
    keymap['52']='4'
    keymap['53']='5'
    keymap['54']='6'
    keymap['55']='7'
    keymap['56']='8'
    keymap['57']='9'
    keymap['59']='semicolon'
    keymap['61']='equals'
    keymap['91']='openbrace'
    keymap['92']='backslash'
    keymap['93']='closebrace'
    keymap['96']='backquote'
    keymap['97']='a'
    keymap['98']='b'
    keymap['99']='c'
    keymap['100']='d'
    keymap['101']='e'
    keymap['102']='f'
    keymap['103']='g'
    keymap['104']='h'
    keymap['105']='i'
    keymap['106']='j'
    keymap['107']='k'
    keymap['108']='l'
    keymap['109']='m'
    keymap['110']='n'
    keymap['111']='o'
    keymap['112']='p'
    keymap['113']='q'
    keymap['114']='r'
    keymap['115']='s'
    keymap['116']='t'
    keymap['117']='u'
    keymap['118']='v'
    keymap['119']='w'
    keymap['120']='x'
    keymap['121']='y'
    keymap['122']='z'
    keymap['127']='del'
    keymap['1073741881']='capslock'
    keymap['1073741882']='f1'
    keymap['1073741883']='f2'
    keymap['1073741884']='f3'
    keymap['1073741885']='f4'
    keymap['1073741886']='f5'
    keymap['1073741887']='f6'
    keymap['1073741888']='f7'
    keymap['1073741889']='f8'
    keymap['1073741890']='f9'
    keymap['1073741891']='f10'
    keymap['1073741892']='f11'
    keymap['1073741893']='f12'
    keymap['1073741894']='prtscr'
    keymap['1073741895']='scrlock'
    keymap['1073741897']='insert'
    keymap['1073741898']='home'
    keymap['1073741899']='pgup'
    keymap['1073741901']='end'
    keymap['1073741902']='pgdown'
    keymap['1073741903']='right'
    keymap['1073741904']='left'
    keymap['1073741905']='down'
    keymap['1073741906']='up'
    keymap['1073741907']='numlock'
    keymap['1073741908']='slash_pad'
    keymap['1073741909']='asterisk_pad'
    keymap['1073741910']='minus_pad'
    keymap['1073741911']='plus_pad'
    keymap['1073741912']='enter_pad'
    keymap['1073741913']='1_pad'
    keymap['1073741914']='2_pad'
    keymap['1073741915']='3_pad'
    keymap['1073741916']='4_pad'
    keymap['1073741917']='5_pad'
    keymap['1073741918']='6_pad'
    keymap['1073741919']='7_pad'
    keymap['1073741920']='8_pad'
    keymap['1073741921']='9_pad'
    keymap['1073741922']='0_pad'
    keymap['1073741923']='period_pad'
    keymap['1073741927']='equals'
    keymap['1073742048']='lcontrol'
    keymap['1073742049']='lshift'
    keymap['1073742050']='lalt'
    keymap['1073742052']='rcontrol'
    keymap['1073742053']='rshift'
    keymap['1073742054']='ralt'
}

function map_advmame() {
    local input_name=$1
    local key=$2
    local controller=$3
    local value=$4

    # Track how each input was mapped so that we can use it with hotkeys
    if [ -z "${mapped_inputs["$input_name"]}" ]; then
        mapped_inputs["$input_name"]="$value"
    fi

    iniGet "input_map\[$key\]"

    # Merge the mapped value with existing ones
    local merged_value=$(echo "$ini_value" | sed 's/ or /\n/g' | grep -Ev "$controller[^_]|auto" | sed ':a;N;$!ba;s/\n/ or /g')
    if [ -n "$merged_value" ]; then
        merged_value+=' or '
    fi
    merged_value+=$value

    iniDel "input_map\[$key\]"
    iniSet "input_map[$key]" "$merged_value"
}

# There doesn't seem to be a particularly straightforward way to translate a
# button id/value to an advmame button name.  There might be a way using the
# data in https://github.com/libretro/retroarch-joypad-autoconfig, but it seems
# very error-prone.
# 
# Instead, the mappings are hard-coded for now.
function map_advmame_joystick() {
    local input_name=$1
    local input_type=$2
    local input_id=$3
    local input_value=$4

    for (( player=1; player<=$max_players; player++ )); do
        # Look up the advmame configuration key this input maps to
        local key=$(_get_player_key "$input_name" "$player")
        if [ -z "$key" ]; then
            return
        fi

        # Get the guid advmame expects for this player #
        local player_guid
        if [ "$player" == '1' ]; then
            player_guid="$controller_guid"
        else
            player_guid="${controller_guid}_$player"
        fi

        local value
        case "$input_type" in
            hat)
                declare -A sdl_hat_ids=([1]="1,1,1" [2]="1,0,0" [4]="1,1,0" [8]="1,0,1")
                value="joystick_digital[$player_guid,${sdl_hat_ids[$input_value]}]"
                ;;
            axis)
                local direction
                if [[ "$input_value" == '1' ]]; then
                    direction='0'
                else
                    direction='1'
                fi
                value="joystick_digital[$player_guid,0,$input_id,$direction]"
                ;;
            *)
                value="joystick_button[$player_guid,$input_id]"
                ;;
        esac

        # The hotkey only gets mapped for player 1
        if [ "$player" == '1' ] && [ "$input_name" == 'hotkeyenable' ]; then
            hotkey_value=$value
            break
        fi

        map_advmame "$input_name" "$key" "$player_guid" "$value"

        # UI Keys only get mapped for player 1
        if [ "$player" == '1' ]; then
            local ui_key=$(_get_ui_key "$input_name")
            if [ -n "$ui_key" ]; then
                map_advmame "$input_name" "$ui_key" "$player_guid" "$value"
            fi
        fi
    done
}

function map_advmame_keyboard() {
    local input_name=$1
    local input_type=$2
    local input_id=$3
    local input_value=$4

    # Look up the advmame configuration key this input maps to
    local key=$(_get_player_key "$input_name" 1)
    if [ -z "$key" ]; then
        return
    fi

    # Find the corresponding advmame key name for the given sdl id
    local mapping=${keymap["$input_id"]}
    if [ -z "$mapping" ]; then
        return
    fi

    local value="keyboard[0,$mapping]"

    if [ "$input_name" == 'hotkeyenable' ]; then
        hotkey_value=$value
    else
        map_advmame "$input_name" "$key" 'keyboard' "$value"
    fi

    # Map UI-related keys
    local ui_key=$(_get_ui_key "$input_name")
    if [ -n "$ui_key" ]; then
        map_advmame "$input_name" "$ui_key" 'keyboard' "$value"
    fi
}

function _onend_advmame() {
    local controller=$1

    # If a hotkey was defined, set up all the pairings now
    if [ -n "$hotkey_value" ]; then
        for input_name in "${!mapped_inputs[@]}"; do
            local pair_value=${mapped_inputs[$input_name]}

            # Check if there's a hotkey configuration for this input
            local hotkey=$(_get_hotkey "$input_name")

            if [ -n "$hotkey" ]; then
                map_advmame "$input_name" "$hotkey" "$controller" "$hotkey_value $pair_value"
            fi
        done
    fi

    mv '/tmp/advmame.rc' "$advmame_config_path"
}

function onend_advmame_joystick() {
    _onend_advmame "$controller_guid"
}

function onend_advmame_keyboard() {
    _onend_advmame 'keyboard'
}
