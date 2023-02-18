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

function onstart_hypseus_keyboard() {
    onstart_hypseus

    # Overwrite existing p1/p2 keyboard controls
    sed -i 's/^\(KEY_[^ ]*\) = [^ ]* [^ ]*\(.*\)$/\1 = 0 0\2/g' /opt/retropie/configs/daphne/hypinput.ini

    declare -Ag hypseuskeymap
    # SDL codes from https://wiki.libsdl.org/SDLKeycodeLookup
    hypseuskeymap["0"]="SDLK_UNKNOWN"
    hypseuskeymap["8"]="SDLK_BACKSPACE"
    hypseuskeymap["9"]="SDLK_TAB"
    hypseuskeymap["13"]="SDLK_RETURN"
    hypseuskeymap["27"]="SDLK_ESCAPE"
    hypseuskeymap["32"]="SDLK_SPACE"
    hypseuskeymap["33"]="SDLK_EXCLAIM"
    hypseuskeymap["34"]="SDLK_QUOTEDBL"
    hypseuskeymap["35"]="SDLK_HASH"
    hypseuskeymap["36"]="SDLK_DOLLAR"
    hypseuskeymap["37"]="SDLK_PERCENT"
    hypseuskeymap["38"]="SDLK_AMPERSAND"
    hypseuskeymap["39"]="SDLK_QUOTE"
    hypseuskeymap["40"]="SDLK_LEFTPAREN"
    hypseuskeymap["41"]="SDLK_RIGHTPAREN"
    hypseuskeymap["42"]="SDLK_ASTERISK"
    hypseuskeymap["43"]="SDLK_PLUS"
    hypseuskeymap["44"]="SDLK_COMMA"
    hypseuskeymap["45"]="SDLK_MINUS"
    hypseuskeymap["46"]="SDLK_PERIOD"
    hypseuskeymap["47"]="SDLK_SLASH"
    hypseuskeymap["48"]="SDLK_0"
    hypseuskeymap["49"]="SDLK_1"
    hypseuskeymap["50"]="SDLK_2"
    hypseuskeymap["51"]="SDLK_3"
    hypseuskeymap["52"]="SDLK_4"
    hypseuskeymap["53"]="SDLK_5"
    hypseuskeymap["54"]="SDLK_6"
    hypseuskeymap["55"]="SDLK_7"
    hypseuskeymap["56"]="SDLK_8"
    hypseuskeymap["57"]="SDLK_9"
    hypseuskeymap["58"]="SDLK_COLON"
    hypseuskeymap["59"]="SDLK_SEMICOLON"
    hypseuskeymap["60"]="SDLK_LESS"
    hypseuskeymap["61"]="SDLK_EQUALS"
    hypseuskeymap["62"]="SDLK_GREATER"
    hypseuskeymap["63"]="SDLK_QUESTION"
    hypseuskeymap["64"]="SDLK_AT"
    hypseuskeymap["91"]="SDLK_LEFTBRACKET"
    hypseuskeymap["92"]="SDLK_BACKSLASH"
    hypseuskeymap["93"]="SDLK_RIGHTBRACKET"
    hypseuskeymap["94"]="SDLK_CARET"
    hypseuskeymap["95"]="SDLK_UNDERSCORE"
    hypseuskeymap["96"]="SDLK_BACKQUOTE"
    hypseuskeymap["97"]="SDLK_a"
    hypseuskeymap["98"]="SDLK_b"
    hypseuskeymap["99"]="SDLK_c"
    hypseuskeymap["100"]="SDLK_d"
    hypseuskeymap["101"]="SDLK_e"
    hypseuskeymap["102"]="SDLK_f"
    hypseuskeymap["103"]="SDLK_g"
    hypseuskeymap["104"]="SDLK_h"
    hypseuskeymap["105"]="SDLK_i"
    hypseuskeymap["106"]="SDLK_j"
    hypseuskeymap["107"]="SDLK_k"
    hypseuskeymap["108"]="SDLK_l"
    hypseuskeymap["109"]="SDLK_m"
    hypseuskeymap["110"]="SDLK_n"
    hypseuskeymap["111"]="SDLK_o"
    hypseuskeymap["112"]="SDLK_p"
    hypseuskeymap["113"]="SDLK_q"
    hypseuskeymap["114"]="SDLK_r"
    hypseuskeymap["115"]="SDLK_s"
    hypseuskeymap["116"]="SDLK_t"
    hypseuskeymap["117"]="SDLK_u"
    hypseuskeymap["118"]="SDLK_v"
    hypseuskeymap["119"]="SDLK_w"
    hypseuskeymap["120"]="SDLK_x"
    hypseuskeymap["121"]="SDLK_y"
    hypseuskeymap["122"]="SDLK_z"
    hypseuskeymap["127"]="SDLK_DELETE"
    hypseuskeymap["1073741881"]="SDLK_CAPSLOCK"
    hypseuskeymap["1073741882"]="SDLK_F1"
    hypseuskeymap["1073741883"]="SDLK_F2"
    hypseuskeymap["1073741884"]="SDLK_F3"
    hypseuskeymap["1073741885"]="SDLK_F4"
    hypseuskeymap["1073741886"]="SDLK_F5"
    hypseuskeymap["1073741887"]="SDLK_F6"
    hypseuskeymap["1073741888"]="SDLK_F7"
    hypseuskeymap["1073741889"]="SDLK_F8"
    hypseuskeymap["1073741890"]="SDLK_F9"
    hypseuskeymap["1073741891"]="SDLK_F10"
    hypseuskeymap["1073741892"]="SDLK_F11"
    hypseuskeymap["1073741893"]="SDLK_F12"
    hypseuskeymap["1073741894"]="SDLK_PRINTSCREEN"
    hypseuskeymap["1073741895"]="SDLK_SCROLLLOCK"
    hypseuskeymap["1073741896"]="SDLK_PAUSE"
    hypseuskeymap["1073741897"]="SDLK_INSERT"
    hypseuskeymap["1073741898"]="SDLK_HOME"
    hypseuskeymap["1073741899"]="SDLK_PAGEUP"
    hypseuskeymap["1073741901"]="SDLK_END"
    hypseuskeymap["1073741902"]="SDLK_PAGEDOWN"
    hypseuskeymap["1073741903"]="SDLK_RIGHT"
    hypseuskeymap["1073741904"]="SDLK_LEFT"
    hypseuskeymap["1073741905"]="SDLK_DOWN"
    hypseuskeymap["1073741906"]="SDLK_UP"
    hypseuskeymap["1073741907"]="SDLK_NUMLOCKCLEAR"
    hypseuskeymap["1073741908"]="SDLK_KP_DIVIDE"
    hypseuskeymap["1073741909"]="SDLK_KP_MULTIPLY"
    hypseuskeymap["1073741910"]="SDLK_KP_MINUS"
    hypseuskeymap["1073741911"]="SDLK_KP_PLUS"
    hypseuskeymap["1073741912"]="SDLK_KP_ENTER"
    hypseuskeymap["1073741913"]="SDLK_KP_1"
    hypseuskeymap["1073741914"]="SDLK_KP_2"
    hypseuskeymap["1073741915"]="SDLK_KP_3"
    hypseuskeymap["1073741916"]="SDLK_KP_4"
    hypseuskeymap["1073741917"]="SDLK_KP_5"
    hypseuskeymap["1073741918"]="SDLK_KP_6"
    hypseuskeymap["1073741919"]="SDLK_KP_7"
    hypseuskeymap["1073741920"]="SDLK_KP_8"
    hypseuskeymap["1073741921"]="SDLK_KP_9"
    hypseuskeymap["1073741922"]="SDLK_KP_0"
    hypseuskeymap["1073741923"]="SDLK_KP_PERIOD"
    hypseuskeymap["1073741925"]="SDLK_APPLICATION"
    hypseuskeymap["1073741926"]="SDLK_POWER"
    hypseuskeymap["1073741927"]="SDLK_KP_EQUALS"
    hypseuskeymap["1073741928"]="SDLK_F13"
    hypseuskeymap["1073741929"]="SDLK_F14"
    hypseuskeymap["1073741930"]="SDLK_F15"
    hypseuskeymap["1073741931"]="SDLK_F16"
    hypseuskeymap["1073741932"]="SDLK_F17"
    hypseuskeymap["1073741933"]="SDLK_F18"
    hypseuskeymap["1073741934"]="SDLK_F19"
    hypseuskeymap["1073741935"]="SDLK_F20"
    hypseuskeymap["1073741936"]="SDLK_F21"
    hypseuskeymap["1073741937"]="SDLK_F22"
    hypseuskeymap["1073741938"]="SDLK_F23"
    hypseuskeymap["1073741939"]="SDLK_F24"
    hypseuskeymap["1073741940"]="SDLK_EXECUTE"
    hypseuskeymap["1073741941"]="SDLK_HELP"
    hypseuskeymap["1073741942"]="SDLK_MENU"
    hypseuskeymap["1073741943"]="SDLK_SELECT"
    hypseuskeymap["1073741944"]="SDLK_STOP"
    hypseuskeymap["1073741945"]="SDLK_AGAIN"
    hypseuskeymap["1073741946"]="SDLK_UNDO"
    hypseuskeymap["1073741947"]="SDLK_CUT"
    hypseuskeymap["1073741948"]="SDLK_COPY"
    hypseuskeymap["1073741949"]="SDLK_PASTE"
    hypseuskeymap["1073741950"]="SDLK_FIND"
    hypseuskeymap["1073741951"]="SDLK_MUTE"
    hypseuskeymap["1073741952"]="SDLK_VOLUMEUP"
    hypseuskeymap["1073741953"]="SDLK_VOLUMEDOWN"
    hypseuskeymap["1073741957"]="SDLK_KP_COMMA"
    hypseuskeymap["1073741958"]="SDLK_KP_EQUALSAS400"
    hypseuskeymap["1073741977"]="SDLK_ALTERASE"
    hypseuskeymap["1073741978"]="SDLK_SYSREQ"
    hypseuskeymap["1073741979"]="SDLK_CANCEL"
    hypseuskeymap["1073741980"]="SDLK_CLEAR"
    hypseuskeymap["1073741981"]="SDLK_PRIOR"
    hypseuskeymap["1073741982"]="SDLK_RETURN2"
    hypseuskeymap["1073741983"]="SDLK_SEPARATOR"
    hypseuskeymap["1073741984"]="SDLK_OUT"
    hypseuskeymap["1073741985"]="SDLK_OPER"
    hypseuskeymap["1073741986"]="SDLK_CLEARAGAIN"
    hypseuskeymap["1073741987"]="SDLK_CRSEL"
    hypseuskeymap["1073741988"]="SDLK_EXSEL"
    hypseuskeymap["1073742000"]="SDLK_KP_00"
    hypseuskeymap["1073742001"]="SDLK_KP_000"
    hypseuskeymap["1073742002"]="SDLK_THOUSANDSSEPARATOR"
    hypseuskeymap["1073742003"]="SDLK_DECIMALSEPARATOR"
    hypseuskeymap["1073742004"]="SDLK_CURRENCYUNIT"
    hypseuskeymap["1073742005"]="SDLK_CURRENCYSUBUNIT"
    hypseuskeymap["1073742006"]="SDLK_KP_LEFTPAREN"
    hypseuskeymap["1073742007"]="SDLK_KP_RIGHTPAREN"
    hypseuskeymap["1073742008"]="SDLK_KP_LEFTBRACE"
    hypseuskeymap["1073742009"]="SDLK_KP_RIGHTBRACE"
    hypseuskeymap["1073742010"]="SDLK_KP_TAB"
    hypseuskeymap["1073742011"]="SDLK_KP_BACKSPACE"
    hypseuskeymap["1073742012"]="SDLK_KP_A"
    hypseuskeymap["1073742013"]="SDLK_KP_B"
    hypseuskeymap["1073742014"]="SDLK_KP_C"
    hypseuskeymap["1073742015"]="SDLK_KP_D"
    hypseuskeymap["1073742016"]="SDLK_KP_E"
    hypseuskeymap["1073742017"]="SDLK_KP_F"
    hypseuskeymap["1073742018"]="SDLK_KP_XOR"
    hypseuskeymap["1073742019"]="SDLK_KP_POWER"
    hypseuskeymap["1073742020"]="SDLK_KP_PERCENT"
    hypseuskeymap["1073742021"]="SDLK_KP_LESS"
    hypseuskeymap["1073742022"]="SDLK_KP_GREATER"
    hypseuskeymap["1073742023"]="SDLK_KP_AMPERSAND"
    hypseuskeymap["1073742024"]="SDLK_KP_DBLAMPERSAND"
    hypseuskeymap["1073742025"]="SDLK_KP_VERTICALBAR"
    hypseuskeymap["1073742026"]="SDLK_KP_DBLVERTICALBAR"
    hypseuskeymap["1073742027"]="SDLK_KP_COLON"
    hypseuskeymap["1073742028"]="SDLK_KP_HASH"
    hypseuskeymap["1073742029"]="SDLK_KP_SPACE"
    hypseuskeymap["1073742030"]="SDLK_KP_AT"
    hypseuskeymap["1073742031"]="SDLK_KP_EXCLAM"
    hypseuskeymap["1073742032"]="SDLK_KP_MEMSTORE"
    hypseuskeymap["1073742033"]="SDLK_KP_MEMRECALL"
    hypseuskeymap["1073742034"]="SDLK_KP_MEMCLEAR"
    hypseuskeymap["1073742035"]="SDLK_KP_MEMADD"
    hypseuskeymap["1073742036"]="SDLK_KP_MEMSUBTRACT"
    hypseuskeymap["1073742037"]="SDLK_KP_MEMMULTIPLY"
    hypseuskeymap["1073742038"]="SDLK_KP_MEMDIVIDE"
    hypseuskeymap["1073742039"]="SDLK_KP_PLUSMINUS"
    hypseuskeymap["1073742040"]="SDLK_KP_CLEAR"
    hypseuskeymap["1073742041"]="SDLK_KP_CLEARENTRY"
    hypseuskeymap["1073742042"]="SDLK_KP_BINARY"
    hypseuskeymap["1073742043"]="SDLK_KP_OCTAL"
    hypseuskeymap["1073742044"]="SDLK_KP_DECIMAL"
    hypseuskeymap["1073742045"]="SDLK_KP_HEXADECIMAL"
    hypseuskeymap["1073742048"]="SDLK_LCTRL"
    hypseuskeymap["1073742049"]="SDLK_LSHIFT"
    hypseuskeymap["1073742050"]="SDLK_LALT"
    hypseuskeymap["1073742051"]="SDLK_LGUI"
    hypseuskeymap["1073742052"]="SDLK_RCTRL"
    hypseuskeymap["1073742053"]="SDLK_RSHIFT"
    hypseuskeymap["1073742054"]="SDLK_RALT"
    hypseuskeymap["1073742055"]="SDLK_RGUI"
    hypseuskeymap["1073742081"]="SDLK_MODE"
    hypseuskeymap["1073742082"]="SDLK_AUDIONEXT"
    hypseuskeymap["1073742083"]="SDLK_AUDIOPREV"
    hypseuskeymap["1073742084"]="SDLK_AUDIOSTOP"
    hypseuskeymap["1073742085"]="SDLK_AUDIOPLAY"
    hypseuskeymap["1073742086"]="SDLK_AUDIOMUTE"
    hypseuskeymap["1073742087"]="SDLK_MEDIASELECT"
    hypseuskeymap["1073742088"]="SDLK_WWW"
    hypseuskeymap["1073742089"]="SDLK_MAIL"
    hypseuskeymap["1073742090"]="SDLK_CALCULATOR"
    hypseuskeymap["1073742091"]="SDLK_COMPUTER"
    hypseuskeymap["1073742092"]="SDLK_AC_SEARCH"
    hypseuskeymap["1073742093"]="SDLK_AC_HOME"
    hypseuskeymap["1073742094"]="SDLK_AC_BACK"
    hypseuskeymap["1073742095"]="SDLK_AC_FORWARD"
    hypseuskeymap["1073742096"]="SDLK_AC_STOP"
}

function onstart_hypseus_joystick() {
    onstart_hypseus

    # Overwrite existing p1/p2 joystick controls
    sed -i 's/^\(KEY_[^ ]* = [^ ]* [^ ]*\).*$/\1 0/g' /opt/retropie/configs/daphne/hypinput.ini
}

function onstart_hypseus() {
    local -r device_mapping_file="$configdir/daphne/hypinput-$DEVICE_NAME.ini"
    local -r force_joy_file="$configdir/daphne/hypinput-forcejoy.ini"
    local -r force_key_file="$configdir/daphne/hypinput-forcekey.ini"

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

    # Device-specific config
    truncate -s0 "$device_mapping_file"
}

function map_hypseus_keyboard() {
    local input_name="$1"
    local input_type="$2"
    local input_id="$3"
    local input_value="$4"

    local mapping_file="$configdir/daphne/hypinput.ini"
    local force_key_file="$configdir/daphne/hypinput-forcekey.ini"

    local key=$(_get_hypseus_key "$input_name" "$input_type")
    if [ -z "$key" ]; then
        return
    fi

    local key_regex="^$key = ([^ ]*) ([^ ]*)\$"
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
        key1="${hypseuskeymap[$input_id]}"
        key2="0"
    fi

    # Get current joystick buttons
    while read -r line; do
        if [[ "$line" =~ $full_regex ]]; then
            button="${BASH_REMATCH[3]}"
            axis="${BASH_REMATCH[4]}"
        fi
    done < "$mapping_file"

    if [[ -n "$axis" ]]; then
        sed -i "s/^$key = .* .* .*\$/$key = $key1 $key2 $button $axis/g" "$mapping_file"
    else
        sed -i "s/^$key = .* .* .*\$/$key = $key1 $key2 $button/g" "$mapping_file"
    fi
}

function map_hypseus_joystick() {
    local input_name="$1"
    local input_type="$2"
    local input_id="$3"
    local input_value="$4"

    local mapping_file="$configdir/daphne/hypinput.ini"
    local device_mapping_file="$configdir/daphne/hypinput-$DEVICE_NAME.ini"
    local force_joy_file="$configdir/daphne/hypinput-forcejoy.ini"

    local key=$(_get_hypseus_key "$input_name" "$input_type")
    if [ -z "$key" ]; then
        return
    fi

    local button_regex="^$key = ([^ ]*) ?([^ ]*)\$"
    local full_regex="^$key = ([^ ]*) ([^ ]*) ([^ ]*) ?([^ ]*)\$"
    local line
    local key1
    local key2
    local button
    local axis

    # Get the current keys / button / axis defined
    while read -r line; do
        if [[ "$line" =~ $full_regex ]]; then
            key1="${BASH_REMATCH[1]}"
            key2="${BASH_REMATCH[2]}"

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
                axis=""
            fi
        fi
    done < "$mapping_file"

    # See if this button is specified in the override file...
    while read -r line; do
        if [[ "$line" =~ $button_regex ]]; then
            button="${BASH_REMATCH[1]}"
            axis="${BASH_REMATCH[2]}"
        fi
    done < "$force_joy_file"

    # Write new button config
    if [[ -n "$axis" ]]; then
        sed -i "s/^$key = .* .* .*\$/$key = $key1 $key2 $button $axis/g" "$mapping_file"
        echo "$key = $button $axis" >> "$device_mapping_file"
    else
        sed -i "s/^$key = .* .* .*\$/$key = $key1 $key2 $button/g" "$mapping_file"
        echo "$key = $button" >> "$device_mapping_file"
    fi
}


function _get_hypseus_key() {
    local input_name=$1
    local input_type=$2

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
            key="KEY_PAUSE"
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
            key="KEY_COIN1"
            ;;
        rightanalogleft)
            key="KEY_QUIT"
            ;;
        *)
            if [ "$input_type" == 'axis' ]; then
                case "$input_name" in
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
            fi
            ;;
    esac

    echo "$key"
}
