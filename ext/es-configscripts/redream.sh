#!/usr/bin/env bash

# Path to the redream configuration where controllers are defined
redream_config_path="$configdir/dreamcast/redream/redream.cfg"

function check_redream() {
    [[ ! -d "$rootdir/emulators/redream" ]] && return 1
    return 0
}

function _onstart_redream() {
    local name=$1

    touch "$redream_config_path"
    iniConfig '=' '' "$redream_config_path"

    declare -g redream_profile_key=''

    # Look for an existing profile for this controller
    if [ -f "$redream_config_path" ]; then
        redream_profile_key=$(grep "name:$name" "$redream_config_path" | head -n 1 | grep -oE '^[^=]+')
    fi

    if [ -z "$redream_profile_key" ]; then
        # No existing profile: determine the next profile id to use
        local next_profile_id=0
        while iniGet "profile$next_profile_id" && [ -n "$ini_value" ]; do
            next_profile_id=$(($next_profile_id + 1))
        done

        redream_profile_key="profile$next_profile_id"
    fi

    declare -g redream_profile_value
    redream_profile_value="name:$name,type:controller,deadzone:12,crosshair:1"
}

function onstart_redream_joystick() {
    _onstart_redream "$DEVICE_GUID"
}

function onstart_redream_keyboard() {
    _onstart_redream 'keyboard0'

    # For keyboard, exit is hard-coded to the ESC key to match other
    # similarly configured standalone emulators
    redream_profile_value+=',exit:escape'

    declare -Ag redream_keymap

    # SDL codes from https://wiki.libsdl.org/SDLKeycodeLookup
    redream_keymap['8']='backspace'
    redream_keymap['9']='tab'
    redream_keymap['13']='return'
    redream_keymap['27']='escape'
    redream_keymap['32']='space'
    redream_keymap['39']="'"
    redream_keymap['42']='*'
    redream_keymap['43']='+'
    redream_keymap['44']=','
    redream_keymap['45']='-'
    redream_keymap['46']='.'
    redream_keymap['47']='/'
    redream_keymap['48']='0'
    redream_keymap['49']='1'
    redream_keymap['50']='2'
    redream_keymap['51']='3'
    redream_keymap['52']='4'
    redream_keymap['53']='5'
    redream_keymap['54']='6'
    redream_keymap['55']='7'
    redream_keymap['56']='8'
    redream_keymap['57']='9'
    redream_keymap['59']=';'
    redream_keymap['61']='='
    redream_keymap['91']='['
    redream_keymap['92']='\\'
    redream_keymap['93']=']'
    redream_keymap['96']='`'
    redream_keymap['97']='a'
    redream_keymap['98']='b'
    redream_keymap['99']='c'
    redream_keymap['100']='d'
    redream_keymap['101']='e'
    redream_keymap['102']='f'
    redream_keymap['103']='g'
    redream_keymap['104']='h'
    redream_keymap['105']='i'
    redream_keymap['106']='j'
    redream_keymap['107']='k'
    redream_keymap['108']='l'
    redream_keymap['109']='m'
    redream_keymap['110']='n'
    redream_keymap['111']='o'
    redream_keymap['112']='p'
    redream_keymap['113']='q'
    redream_keymap['114']='r'
    redream_keymap['115']='s'
    redream_keymap['116']='t'
    redream_keymap['117']='u'
    redream_keymap['118']='v'
    redream_keymap['119']='w'
    redream_keymap['120']='x'
    redream_keymap['121']='y'
    redream_keymap['122']='z'
    redream_keymap['127']='delete'
    redream_keymap['1073741881']='capslock'
    redream_keymap['1073741882']='f1'
    redream_keymap['1073741883']='f2'
    redream_keymap['1073741884']='f3'
    redream_keymap['1073741885']='f4'
    redream_keymap['1073741886']='f5'
    redream_keymap['1073741887']='f6'
    redream_keymap['1073741888']='f7'
    redream_keymap['1073741889']='f8'
    redream_keymap['1073741890']='f9'
    redream_keymap['1073741891']='f10'
    redream_keymap['1073741892']='f11'
    redream_keymap['1073741893']='f12'
    redream_keymap['1073741895']='scrolllock'
    redream_keymap['1073741897']='insert'
    redream_keymap['1073741898']='home'
    redream_keymap['1073741899']='pageup'
    redream_keymap['1073741901']='end'
    redream_keymap['1073741902']='pagedown'
    redream_keymap['1073741903']='right'
    redream_keymap['1073741904']='left'
    redream_keymap['1073741905']='down'
    redream_keymap['1073741906']='up'
    redream_keymap['1073741907']='kp_numlock'
    redream_keymap['1073741908']='kp_divide'
    redream_keymap['1073741909']='kp_multiply'
    redream_keymap['1073741910']='kp_minus'
    redream_keymap['1073741911']='kp_plus'
    redream_keymap['1073741912']='kp_return'
    redream_keymap['1073741913']='kp_1'
    redream_keymap['1073741914']='kp_2'
    redream_keymap['1073741915']='kp_3'
    redream_keymap['1073741916']='kp_4'
    redream_keymap['1073741917']='kp_5'
    redream_keymap['1073741918']='kp_6'
    redream_keymap['1073741919']='kp_7'
    redream_keymap['1073741920']='kp_8'
    redream_keymap['1073741921']='kp_9'
    redream_keymap['1073741922']='kp_0'
    redream_keymap['1073741923']='kp_period'
    redream_keymap['1073741927']='kp_equals'
    redream_keymap['1073742048']='lctrl'
    redream_keymap['1073742049']='lshift'
    redream_keymap['1073742050']='lalt'
    redream_keymap['1073742052']='rctrl'
    redream_keymap['1073742053']='rshift'
    redream_keymap['1073742054']='ralt'
}

# Generates the configuration key for a given ES input name
function _get_config_key() {
    local input_name=$1
    local key=''

    case "$input_name" in
        up)
            key='dpad_up'
            ;;
        down)
            key='dpad_down'
            ;;
        left)
            key='dpad_left'
            ;;
        right)
            key='dpad_right'
            ;;
        a|b|x|y|start)
            key="$input_name"
            ;;
        leftbottom|leftshoulder)
            key='turbo'
            ;;
        rightbottom|rightshoulder)
            key='lcd'
            ;;
        lefttop|lefttrigger)
            key='ltrig'
            ;;
        righttop|righttrigger)
            key='rtrig'
            ;;
        select)
            key='menu'
            ;;
        leftanalogleft)
            key='ljoy_left'
            ;;
        leftanalogright)
            key='ljoy_right'
            ;;
        leftanalogup)
            key='ljoy_up'
            ;;
        leftanalogdown)
            key='ljoy_down'
            ;;
        *)
            ;;
    esac

    echo "$key"
}

function map_redream_joystick() {
    local input_name=$1
    local input_type=$2
    local input_id=$3
    local input_value=$4

    local key=$(_get_config_key "$input_name")
    if [ -z "$key" ]; then
        return
    fi

    local value
    case "$input_type" in
        hat)
            # up, right, down, left
            declare -A sdl_hat_ids=([1]="0" [2]="3" [4]="1" [8]="2")
            value="hat${sdl_hat_ids[$input_value]}"
            ;;
        axis)
            if [[ "$input_value" == '1' ]]; then
                value="+axis$input_id"
            else
                value="-axis$input_id"
            fi
            ;;
        *)
            value="joy$input_id"
            ;;
    esac

    redream_profile_value+=",$key:$value"
}

function map_redream_keyboard() {
    local input_name=$1
    local input_type=$2
    local input_id=$3
    local input_value=$4

    local key=$(_get_config_key "$input_name")
    if [ -z "$key" ]; then
        return
    fi

    local value=${redream_keymap[$input_id]}
    if [ -n "$value" ]; then
        redream_profile_value+=",$key:$value"
    fi
}

function _onend_redream() {
    iniSet "$redream_profile_key" "$redream_profile_value"
}

function onend_redream_joystick() {
    _onend_redream
}

function onend_redream_keyboard() {
    _onend_redream
}
