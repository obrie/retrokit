#!/usr/bin/env bash

# Path to the drastic configuration where controllers are defined
drastic_config_path="$configdir/nds/drastic/config/drastic.cfg"

function _onstart_drastic() {
    local controller=$1

    cp "$drastic_config_path" '/tmp/drastic.cfg'
    iniConfig ' = ' '' '/tmp/drastic.cfg'

    declare -g profile_key

    local all_config_keys=(
        UP DOWN LEFT RIGHT A B X Y L R START SELECT HINGE
        TOUCH_CURSOR_UP TOUCH_CURSOR_DOWN TOUCH_CURSOR_LEFT TOUCH_CURSOR_RIGHT TOUCH_CURSOR_PRESS
        MENU SAVE_STATE LOAD_STATE FAST_FORWARD SWAP_SCREENS SWAP_ORIENTATION_A SWAP_ORIENTATION_B
        LOAD_GAME QUIT
        UI_UP UI_DOWN UI_LEFT UI_RIGHT UI_SELECT UI_BACK UI_EXIT UI_PAGE_UP UI_PAGE_DOWN UI_SWITCH
    )
    for config_key in "${all_config_keys[@]}"; do
        iniDel "controllers_$controller\[CONTROL_INDEX_$config_key\]"
        iniSet "controllers_$controller[CONTROL_INDEX_$config_key]" 65535
    done

    # Menu - M
    iniDel "controllers_a\[CONTROL_INDEX_MENU\]"
    iniSet "controllers_a[CONTROL_INDEX_MENU]" 109

    # Quit - Escape
    iniDel "controllers_a\[CONTROL_INDEX_QUIT\]"
    iniSet "controllers_a[CONTROL_INDEX_QUIT]" 27
}

function onstart_drastic_joystick() {
    _onstart_drastic 'b'
}

function onstart_drastic_keyboard() {
    _onstart_drastic 'a'
}

# Generates the configuration key for a given ES input name
function _get_config_keys() {
    local input_name=$1
    local key=''

    case "$input_name" in
        up)
            keys=(UP UI_UP)
            ;;
        down)
            keys=(DOWN UI_DOWN)
            ;;
        left)
            keys=(LEFT UI_LEFT)
            ;;
        right)
            keys=(RIGHT UI_RIGHT)
            ;;
        a)
            keys=(A UI_SELECT)
            ;;
        b)
            keys=(B UI_BACK)
            ;;
        x)
            keys=(X UI_EXIT)
            ;;
        y)
            keys=(Y UI_SWITCH)
            ;;
        leftbottom|leftshoulder)
            keys=(L UI_PAGE_DOWN)
            ;;
        rightbottom|rightshoulder)
            key=(R UI_PAGE_UP)
            ;;
        start)
            keys=(START)
            ;;
        select)
            keys=(SELECT)
            ;;
        leftanalogleft)
            keys=(TOUCH_CURSOR_LEFT)
            ;;
        leftanalogright)
            keys=(TOUCH_CURSOR_RIGHT)
            ;;
        leftanalogup)
            keys=(TOUCH_CURSOR_UP)
            ;;
        leftanalogdown)
            keys=(TOUCH_CURSOR_DOWN)
            ;;
        rightanalogleft)
            keys=(QUIT)
            ;;
        rightanalogright)
            keys=(MENU)
            ;;
        rightanalogup)
            keys=(SAVE_STATE)
            ;;
        rightanalogdown)
            keys=(LOAD_STATE)
            ;;
        *)
            ;;
    esac

    echo "${keys[@]}"
}

function _map_drastic() {
    local controller=$1
    local key=$2
    local value=$3

    iniDel "controls_$controller\[CONTROL_INDEX_$key\]"
    iniSet "controls_$controller[CONTROL_INDEX_$key]" "$value"
}

function map_drastic_joystick() {
    local input_name=$1
    local input_type=$2
    local input_id=$3
    local input_value=$4

    local keys=($(_get_config_keys "$input_name"))
    if [ ${#keys[@]} -eq 0 ]; then
        return
    fi

    for key in "${keys[@]}"; do
        local value
        case "$input_type" in
            hat)
                # up, right, down, left
                declare -A sdl_hat_ids=([1]="0" [2]="1" [4]="2" [8]="4")
                value=$((1089 + ${sdl_hat_ids[$input_value]}))
                ;;
            axis)
                if [[ "$input_value" == '1' ]]; then
                    value=$((1152 + $input_id))
                else
                    value=$((1216 + $input_id))
                fi
                ;;
            *)
                value=$((1024 + $input_id))
                ;;
        esac

        _map_drastic 'b' "$key", "$value"
    done
}

function map_drastic_keyboard() {
    local input_name=$1
    local input_type=$2
    local input_id=$3
    local input_value=$4

    local keys=($(_get_config_keys "$input_name"))
    if [ ${#keys[@]} -eq 0 ]; then
        return
    fi

    for key in "${keys[@]}"; do
        local value
        if [ "$input_id" -lt 1073741881 ]; then
            # 1073741881 is the SDL key code at which point the key ids
            # jump to the 300's
            value=$input_id
        else
            # Start at 313
            value=$(($input_id - 1073741568))
        fi

        _map_drastic 'a' "$key" "$value"
    done
}

function _onend_drastic() {
    iniSet "$profile_key" "$profile_value"
}

function onend_drastic_joystick() {
    _onend_drastic
}

function onend_drastic_keyboard() {
    _onend_drastic
}

controls_b[CONTROL_INDEX_QUIT] = 65535
