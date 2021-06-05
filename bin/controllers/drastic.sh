#!/usr/bin/env bash

# Path to the drastic configuration where controllers are defined
drastic_config_path="$configdir/nds/drastic/config/drastic.cfg"

function check_drastic() {
    [[ ! -f "$configdir/nds/drastic/config" ]] && return 1
    return 0
}

function _onstart_drastic() {
    local controller=$1

    if [ -f "$drastic_config_path" ]; then
        cp "$drastic_config_path" '/tmp/drastic.cfg'
    else
        touch '/tmp/drastic.cfg'
    fi
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
        iniDel "controls_$controller\[CONTROL_INDEX_$config_key\]"
        iniSet "controls_$controller[CONTROL_INDEX_$config_key]" 65535
    done
}

function onstart_drastic_joystick() {
    _onstart_drastic 'b'
}

function onstart_drastic_keyboard() {
    _onstart_drastic 'a'

    # Menu - M
    iniDel "controls_a\[CONTROL_INDEX_MENU\]"
    iniSet "controls_a[CONTROL_INDEX_MENU]" 109

    # Quit - Escape
    iniDel "controls_a\[CONTROL_INDEX_QUIT\]"
    iniSet "controls_a[CONTROL_INDEX_QUIT]" 27
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
            keys=(R UI_PAGE_UP)
            ;;
        leftthumb)
            keys=(TOUCH_CURSOR_PRESS)
            ;;
        rightthumb)
            keys=(TOUCH_CURSOR_PRESS)
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
                value=$((1088 + $input_value))
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

        _map_drastic 'b' "$key" "$value"
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
    cp '/tmp/drastic.cfg' "$drastic_config_path"
}

function onend_drastic_joystick() {
    _onend_drastic
}

function onend_drastic_keyboard() {
    _onend_drastic
}
