#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

# Support for configuration multiplayer keyboards with custom keyboard2,
# keyboard3, keyboard4, etc. input types

function onstart_retroarch-nkb_keyboard() {
    iniConfig " = " '"' "$configdir/all/retroarch.cfg"

    declare -Ag retroarchkeymap
    # SDL codes from https://wiki.libsdl.org/SDLKeycodeLookup
    retroarchkeymap["1073741904"]="left"
    retroarchkeymap["1073741903"]="right"
    retroarchkeymap["1073741906"]="up"
    retroarchkeymap["1073741905"]="down"
    retroarchkeymap["13"]="enter"
    retroarchkeymap["1073741912"]="kp_enter"
    retroarchkeymap["9"]="tab"
    retroarchkeymap["1073741897"]="insert"
    retroarchkeymap["127"]="del"
    retroarchkeymap["1073741901"]="end"
    retroarchkeymap["1073741898"]="home"
    retroarchkeymap["1073742053"]="rshift"
    retroarchkeymap["1073742049"]="shift"
    retroarchkeymap["1073742048"]="ctrl"
    retroarchkeymap["1073742050"]="alt"
    retroarchkeymap["32"]="space"
    retroarchkeymap["27"]="escape"
    retroarchkeymap["43"]="add"
    retroarchkeymap["45"]="subtract"
    retroarchkeymap["1073741911"]="kp_plus"
    retroarchkeymap["1073741910"]="kp_minus"
    retroarchkeymap["1073741882"]="f1"
    retroarchkeymap["1073741883"]="f2"
    retroarchkeymap["1073741884"]="f3"
    retroarchkeymap["1073741885"]="f4"
    retroarchkeymap["1073741886"]="f5"
    retroarchkeymap["1073741887"]="f6"
    retroarchkeymap["1073741888"]="f7"
    retroarchkeymap["1073741889"]="f8"
    retroarchkeymap["1073741890"]="f9"
    retroarchkeymap["1073741891"]="f10"
    retroarchkeymap["1073741892"]="f11"
    retroarchkeymap["1073741893"]="f12"
    retroarchkeymap["48"]="num0"
    retroarchkeymap["49"]="num1"
    retroarchkeymap["50"]="num2"
    retroarchkeymap["51"]="num3"
    retroarchkeymap["52"]="num4"
    retroarchkeymap["53"]="num5"
    retroarchkeymap["54"]="num6"
    retroarchkeymap["55"]="num7"
    retroarchkeymap["56"]="num8"
    retroarchkeymap["57"]="num9"
    retroarchkeymap["1073741899"]="pageup"
    retroarchkeymap["1073741902"]="pagedown"
    retroarchkeymap["1073741922"]="keypad0"
    retroarchkeymap["1073741913"]="keypad1"
    retroarchkeymap["1073741914"]="keypad2"
    retroarchkeymap["1073741915"]="keypad3"
    retroarchkeymap["1073741916"]="keypad4"
    retroarchkeymap["1073741917"]="keypad5"
    retroarchkeymap["1073741918"]="keypad6"
    retroarchkeymap["1073741919"]="keypad7"
    retroarchkeymap["1073741920"]="keypad8"
    retroarchkeymap["1073741921"]="keypad9"
    retroarchkeymap["46"]="period"
    retroarchkeymap["1073741881"]="capslock"
    retroarchkeymap["1073741907"]="numlock"
    retroarchkeymap["8"]="backspace"
    retroarchkeymap["42"]="multiply"
    retroarchkeymap["47"]="divide"
    retroarchkeymap["1073741894"]="print_screen"
    retroarchkeymap["1073741895"]="scroll_lock"
    retroarchkeymap["96"]="backquote"
    retroarchkeymap["1073741896"]="pause"
    retroarchkeymap["39"]="quote"
    retroarchkeymap["44"]="comma"
    retroarchkeymap["45"]="minus"
    retroarchkeymap["47"]="slash"
    retroarchkeymap["59"]="semicolon"
    retroarchkeymap["61"]="equals"
    retroarchkeymap["91"]="leftbracket"
    retroarchkeymap["92"]="backslash"
    retroarchkeymap["93"]="rightbracket"
    retroarchkeymap["1073741923"]="kp_period"
    retroarchkeymap["1073741927"]="kp_equals"
    retroarchkeymap["1073742052"]="rctrl"
    retroarchkeymap["1073742054"]="ralt"
    retroarchkeymap["97"]="a"
    retroarchkeymap["98"]="b"
    retroarchkeymap["99"]="c"
    retroarchkeymap["100"]="d"
    retroarchkeymap["101"]="e"
    retroarchkeymap["102"]="f"
    retroarchkeymap["103"]="g"
    retroarchkeymap["104"]="h"
    retroarchkeymap["105"]="i"
    retroarchkeymap["106"]="j"
    retroarchkeymap["107"]="k"
    retroarchkeymap["108"]="l"
    retroarchkeymap["109"]="m"
    retroarchkeymap["110"]="n"
    retroarchkeymap["111"]="o"
    retroarchkeymap["112"]="p"
    retroarchkeymap["113"]="q"
    retroarchkeymap["114"]="r"
    retroarchkeymap["115"]="s"
    retroarchkeymap["116"]="t"
    retroarchkeymap["117"]="u"
    retroarchkeymap["118"]="v"
    retroarchkeymap["119"]="w"
    retroarchkeymap["120"]="x"
    retroarchkeymap["121"]="y"
    retroarchkeymap["122"]="z"

    # special case for disabled hotkey
    retroarchkeymap["0"]="nul"
}

function onstart_retroarch-nkb_keyboard2() {
    onstart_retroarch-nkb_keyboard
}

function onstart_retroarch-nkb_keyboard3() {
    onstart_retroarch-nkb_keyboard
}

function onstart_retroarch-nkb_keyboard4() {
    onstart_retroarch-nkb_keyboard
}

function __map_retroarch-nkb_keyboard() {
    local input_name="$1"
    local input_type="$2"
    local input_id="$3"
    local input_value="$4"
    local player_id="$5"

    local key
    case "$input_name" in
        up)
            key="up"
            ;;
        down)
            key="down"
            ;;
        left)
            key="left"
            ;;
        right)
            key="right"
            ;;
        a)
            key="a"
            ;;
        b)
            key="b"
            ;;
        x)
            key="x"
            ;;
        y)
            key="y"
            ;;
        leftbottom|leftshoulder)
            key="l"
            ;;
        rightbottom|rightshoulder)
            key="r"
            ;;
        lefttop|lefttrigger)
            key="l2"
            ;;
        righttop|righttrigger)
            key="r2"
            ;;
        leftthumb)
            key="l3"
            ;;
        rightthumb)
            key="r3"
            ;;
        start)
            key="start"
            ;;
        select)
            key="select"
            ;;
        *)
            return
            ;;
    esac

    iniSet "input_player${player_id}_${key}" "${retroarchkeymap[$input_id]}"
}

function map_retroarch-nkb_keyboard2() {
    __map_retroarch-nkb_keyboard "${@}" 2
}

function map_retroarch-nkb_keyboard3() {
    __map_retroarch-nkb_keyboard "${@}" 3
}

function map_retroarch-nkb_keyboard4() {
    __map_retroarch-nkb_keyboard "${@}" 4
}
