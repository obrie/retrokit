#!/usr/bin/env bash

# Adds hypseus autoconfig, based on daphne autoconfig
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

function check_hypseus() {
    [[ ! -d "$configdir/daphne/" ]] && return 1
    return 0
}

function onstart_hypseus_joystick() {
    local -r mapping_file="$configdir/daphne/hypinput.ini"
    local -r force_joy_file="$configdir/daphne/hypinput-forcejoy.ini"
    local -r force_key_file="$configdir/daphne/hypinput-forcekey.ini"

    if [[ ! -f "$mapping_file" ]]; then
        cat > "$mapping_file" << _EOF_
# Sample hypinput.ini
# All key options listed
# Hypseus uses SDL2 Keycodes
#
# The first two entries are SDL2 keyboard codes or names (0 for "none")
#
# Find SDL2 keyboard code information here:
# https://github.com/DirtBagXon/hypseus-singe/blob/master/doc/keylist.txt
#
# Hypseus Singe supports configuration on multiple joysticks
# First joystick is defined as 0, second joystick as 1 etc.
#
# IMPORTANT: Find the joystick button and axis by running:
# jstest /dev/input/js0 || jstest /dev/input/js1
#
# The third number in config is a joystick button code (or 0 for "none")
# Since 0 is reserved for special meaning, joystick button 0 is
# identified as 1. Button 1 is identified as 2, and so on.
#
# Defining 001 (or 1) identifies first joystick(0) button 0
# Defining 111 identifies second joystick(1) button 10
#
# The fourth number in config (if specified) is the joystick axis
# configuration (or 0 for "none"). Since 0 is reserved for
# special meaning, joystick axis 0 is identified as 1.
# Axis 1 is identified as 2, and so on.
#
# Only the first four switches are defined (SWITCH_UP->SWITCH_RIGHT) for axis
#
# Defining -001 (or -1) identifies first joystick(0) axis 0 in negative direction
# Defining +102 identifies second joystick(1) axis 1 in positive direction

# KEY_BUTTON3 Turns scoreboard on/off in lair/ace

[KEYBOARD]
KEY_UP = SDLK_UP SDLK_r 5 -002
KEY_DOWN = SDLK_DOWN SDLK_f 7 +002
KEY_LEFT = SDLK_LEFT SDLK_d 8 -001
KEY_RIGHT = SDLK_RIGHT SDLK_g 6 +001
KEY_COIN1 = SDLK_5 0 1
KEY_COIN2 = SDLK_6 0 0
KEY_START1 = SDLK_1 0 4
KEY_START2 = SDLK_2 0 0
KEY_BUTTON1 = SDLK_LCTRL SDLK_a 14
KEY_BUTTON2 = SDLK_LALT SDLK_s 15
KEY_BUTTON3 = SDLK_SPACE SDLK_d 16
KEY_SKILL1 = SDLK_LSHIFT SDLK_w 0
KEY_SKILL2 = SDLK_z SDLK_i 0
KEY_SKILL3 = SDLK_x SDLK_k 0
KEY_SERVICE = SDLK_9 0 0
KEY_TEST = SDLK_F2 0 0
KEY_RESET = SDLK_0 0 0
KEY_SCREENSHOT = SDLK_F12 0 0
KEY_QUIT = SDLK_ESCAPE SDLK_q 17
KEY_PAUSE = SDLK_p 0 0
KEY_CONSOLE = SDLK_BACKSLASH 0 0
KEY_TILT = SDLK_t 0 0
END
_EOF_
    fi

    if [[ ! -f "$force_joy_file" ]]; then
        cat > "$force_joy_file" << _EOF_
# Hypseus custom joystick mapping
#
# Any inputs defined below will map a joystick button to
# Hypseus input, regardless of remapping that occurs in emulationstation.
#
# Each input is mapped to 1 joystick button (or 0 for "none") and, optionally,
# 1 joystick axis.
#
# Find joystick button codes by running:
# $ jstest /dev/input/js0
# and ADDING ONE to the button code you want.
#
# Example: Quit will always be js button 14 and axis 0 in negative direction
# KEY_QUIT = 15 -001
#
# (Place all entries after [KEYBOARD])

[KEYBOARD]
END
_EOF_
    fi

    if [[ ! -f "$force_key_file" ]]; then
        cat > "$force_key_file" << _EOF_
# Hypseus custom keyboard mapping
#
# Any inputs defined below will map keyboard keys to
# Hpyseus input, regardless of remapping that occurs in emulationstation.
#
# Each input is mapped to 2 keyboard key codes (or 0 for "none")
#
# Find keyboard codes here:
# https://github.com/DirtBagXon/hypseus-singe/blob/master/doc/keylist.txt
#
# Example: Quit will always be key [Esc] or [Q]
# KEY_QUIT = SDLK_ESCAPE SDLK_q
#
# (Place all entries after [KEYBOARD])

[KEYBOARD]
END
_EOF_
    fi
}

function map_hypseus_joystick() {
    local input_name="$1"
    local input_type="$2"
    local input_id="$3"
    local input_value="$4"

    local -r mapping_file="$configdir/daphne/hypinput.ini"
    local -r force_joy_file="$configdir/daphne/hypinput-forcejoy.ini"
    local -r force_key_file="$configdir/daphne/hypinput-forcekey.ini"

    local key
    case "$input_name" in
        up)
            key="KEY_UP"
            ;;
        down)
            key="KEY_DOWN"
            ;;
        left)
            key="KEY_LEFT"
            ;;
        right)
            key="KEY_RIGHT"
            ;;
        a)
            key="KEY_BUTTON1"
            ;;
        b)
            key="KEY_BUTTON2"
            ;;
        x)
            key="KEY_BUTTON3"
            ;;
        y)
            key="KEY_COIN1"
            ;;
        leftbottom|leftshoulder)
            key="KEY_SKILL1"
            ;;
        rightbottom|rightshoulder)
            key="KEY_SKILL2"
            ;;
        lefttop|lefttrigger)
            key="KEY_SKILL3"
            ;;
        righttop|righttrigger)
            key="KEY_SERVICE"
            ;;
        start)
            key="KEY_START1"
            ;;
        select)
            key="KEY_QUIT"
            ;;
        leftanalogleft)
            key="KEY_LEFT"
            ;;
        leftanalogright)
            key="KEY_RIGHT"
            ;;
        leftanalogup)
            key="KEY_UP"
            ;;
        leftanalogdown)
            key="KEY_DOWN"
            ;;
        *)
            return
            ;;
    esac

    local key_regex="^$key = ([^ ]*) ([^ ]*)\$"
    local button_regex="^$key = ([^ ]*) ?([^ ]*)\$"
    local full_regex="^$key = ([^ ]*) ([^ ]*) ([^ ]*) ?([^ ]*)\$"
    local line
    local key1
    local key2
    local button
    local axis

    # See if this key is specified in the override file...
    while read -r line; do
        if [[ "$line" =~ $key_regex ]]; then
            key1="${BASH_REMATCH[1]}"
            key2="${BASH_REMATCH[2]}"
        fi
    done < "$force_key_file"

    # ...otherwise, use the defaults file.
    if [[ -z "$key1" || -z "$key2" ]]; then
        echo "Keymap not found in $force_key_file"
        while read -r line; do
            if [[ "$line" =~ $full_regex ]]; then
                key1="${BASH_REMATCH[1]}"
                key2="${BASH_REMATCH[2]}"
            fi
        done < "$mapping_file"
    fi

    # See if this button is specified in the override file...
    while read -r line; do
        if [[ "$line" =~ $button_regex ]]; then
            button="${BASH_REMATCH[1]}"
            axis="${BASH_REMATCH[2]}"
        fi
    done < "$force_joy_file"

    # ...otherwise, use the config sent to this function.
    if [[ -z "$button" ]]; then
        while read -r line; do
            if [[ "$line" =~ $full_regex ]]; then
                if [[ "$input_type" == "axis" ]]; then
                    button="${BASH_REMATCH[3]}"

                    if [[ "$input_value" == "1" ]]; then
                        axis="+0$((input_id+1))"
                    else
                        axis="-0$((input_id+1))"
                    fi
                elif [[ "$input_type" == "hat" ]]; then
                    button="0"
                    axis="${BASH_REMATCH[4]}"
                else
                    button=$((input_id+1))
                    axis="${BASH_REMATCH[4]}"
                fi
            fi
        done < "$mapping_file"
    fi

    # Write new button config
    if [[ -n "$axis" ]]; then
        sed -i "s/^$key = .* .* .*\$/$key = $key1 $key2 $button $axis/g" "$mapping_file"
    else
        sed -i "s/^$key = .* .* .*\$/$key = $key1 $key2 $button/g" "$mapping_file"
    fi
}