#!/usr/bin/env bash

redream_config_path="$configdir/dreamcast/redream/redream.cfg"

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
            key='exit'
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

function _onstart_redream() {
    local name=$1

    iniConfig '=' '' "$redream_config_path"

    declare -g profile_key

    # Look for an existing profile for this controller
    profile_key=$(grep "name:$name" "$redream_config_path" | head -n 1 | grep -oE '^[^=]+')
    if [ -z "$profile_key" ]; then
        # No existing profile: determine the next profile id to use
        local next_profile_id=0
        while iniGet "profile$next_profile_id" && [ -n "$ini_value" ]; do
            next_profile_id=$(($next_profile_id + 1))
        done

        profile_key="profile$next_profile_id"
    fi

    declare -g profile_value
    profile_value="name:$name,type:controller,deadzone:12,crosshair:1"
}

function onstart_redream_joystick() {
    _onstart_redream "$DEVICE_GUID"
}

function onstart_redream_keyboard() {
    _onstart_redream 'keyboard0'

    profile_value+=',exit:escape'

    declare -Ag keymap

    # SDL codes from https://wiki.libsdl.org/SDLKeycodeLookup
    keymap['8']='backspace'
    keymap['9']='tab'
    keymap['13']='return'
    keymap['27']='escape'
    keymap['32']='space'
    keymap['39']="'"
    keymap['42']='*'
    keymap['43']='+'
    keymap['44']=','
    keymap['45']='-'
    keymap['46']='.'
    keymap['47']='/'
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
    keymap['59']=';'
    keymap['61']='='
    keymap['91']='['
    keymap['92']='\\'
    keymap['93']=']'
    keymap['96']='`'
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
    keymap['127']='delete'
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
    keymap['1073741895']='scrolllock'
    keymap['1073741897']='insert'
    keymap['1073741898']='home'
    keymap['1073741899']='pageup'
    keymap['1073741901']='end'
    keymap['1073741902']='pagedown'
    keymap['1073741903']='right'
    keymap['1073741904']='left'
    keymap['1073741905']='down'
    keymap['1073741906']='up'
    keymap['1073741907']='kp_numlock'
    keymap['1073741908']='kp_divide'
    keymap['1073741909']='kp_multiply'
    keymap['1073741910']='kp_minus'
    keymap['1073741911']='kp_plus'
    keymap['1073741912']='kp_return'
    keymap['1073741913']='kp_1'
    keymap['1073741914']='kp_2'
    keymap['1073741915']='kp_3'
    keymap['1073741916']='kp_4'
    keymap['1073741917']='kp_5'
    keymap['1073741918']='kp_6'
    keymap['1073741919']='kp_7'
    keymap['1073741920']='kp_8'
    keymap['1073741921']='kp_9'
    keymap['1073741922']='kp_0'
    keymap['1073741923']='kp_period'
    keymap['1073741927']='kp_equals'
    keymap['1073742048']='lctrl'
    keymap['1073742049']='lshift'
    keymap['1073742050']='lalt'
    keymap['1073742052']='rctrl'
    keymap['1073742053']='rshift'
    keymap['1073742054']='ralt'
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

    profile_value+=",$key:$value"
}

function map_redream_keyboard() {
    local input_name=$1
    local input_type=$2
    local input_id=$3
    local input_value=$4

    local key
    if [ "$input_name" == 'select' ]; then
        key='menu'
    else
        key=$(_get_config_key "$input_name")
        if [ -z "$key" ]; then
            return
        fi
    fi

    local value=${keymap[$input_id]}
    if [ -n "$value" ]; then
        profile_value+=",$key:$value"
    fi
}

function _onend_redream() {
    iniSet "$profile_key" "$profile_value"
}

function onend_redream_joystick() {
    _onend_redream
}

function onend_redream_keyboard() {
    _onend_redream
}
