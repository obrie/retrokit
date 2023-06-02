#!/usr/bin/env bash

# Path to the sinden base configuration directory
sinden_dir="$rootdir/supplementary/sinden"

function check_sinden() {
    [[ ! -f "$sinden_dir/Player1/LightgunMono.exe.config" ]] && return 1
    return 0
}

function onstart_sinden_keyboard() {
    iniConfig " = " '"' "$configdir/all/retroarch.cfg"

    declare -Ag sinden_keymap

    # SDL codes from https://wiki.libsdl.org/SDLKeycodeLookup
    sinden_keymap['9']='73' # tab
    sinden_keymap['13']='70' # enter
    sinden_keymap['27']='72' # escape
    sinden_keymap['32']='71' # space
    sinden_keymap['44']='79' # ,
    sinden_keymap['45']='80' # -
    sinden_keymap['46']='81' # .
    sinden_keymap['48']='8' # 0
    sinden_keymap['49']='9' # 1
    sinden_keymap['50']='10' # 2
    sinden_keymap['51']='11' # 3
    sinden_keymap['52']='12' # 4
    sinden_keymap['53']='13' # 5
    sinden_keymap['54']='14' # 6
    sinden_keymap['55']='15' # 7
    sinden_keymap['56']='16' # 8
    sinden_keymap['57']='17' # 9
    sinden_keymap['97']='44' # a
    sinden_keymap['98']='45' # b
    sinden_keymap['99']='46' # c
    sinden_keymap['100']='47' # d
    sinden_keymap['101']='48' # e
    sinden_keymap['102']='49' # f
    sinden_keymap['103']='50' # g
    sinden_keymap['104']='51' # h
    sinden_keymap['105']='52' # i
    sinden_keymap['106']='53' # j
    sinden_keymap['107']='54' # k
    sinden_keymap['108']='55' # l
    sinden_keymap['109']='56' # m
    sinden_keymap['110']='57' # n
    sinden_keymap['111']='58' # o
    sinden_keymap['112']='59' # p
    sinden_keymap['113']='60' # q
    sinden_keymap['114']='61' # r
    sinden_keymap['115']='62' # s
    sinden_keymap['116']='63' # t
    sinden_keymap['117']='64' # u
    sinden_keymap['118']='65' # v
    sinden_keymap['119']='66' # w
    sinden_keymap['120']='67' # x
    sinden_keymap['121']='68' # y
    sinden_keymap['122']='69' # z
    sinden_keymap['1073741882']='82' # f1
    sinden_keymap['1073741883']='83' # f2
    sinden_keymap['1073741884']='84' # f3
    sinden_keymap['1073741885']='85' # f4
    sinden_keymap['1073741886']='86' # f5
    sinden_keymap['1073741887']='87' # f6
    sinden_keymap['1073741888']='88' # f7
    sinden_keymap['1073741889']='89' # f8
    sinden_keymap['1073741890']='90' # f9
    sinden_keymap['1073741891']='91' # f10
    sinden_keymap['1073741892']='92' # f11
    sinden_keymap['1073741893']='93' # f12
    sinden_keymap['1073741903']='77' # right
    sinden_keymap['1073741904']='76' # left
    sinden_keymap['1073741905']='75' # down
    sinden_keymap['1073741906']='74' # up
    sinden_keymap['1073742050']='7' # lalt

    declare -Ag sinden_retroarchkeymap

    # SDL codes from https://wiki.libsdl.org/SDLKeycodeLookup
    sinden_retroarchkeymap['9']='tab'
    sinden_retroarchkeymap['13']='enter'
    sinden_retroarchkeymap['27']='escape'
    sinden_retroarchkeymap['32']='space'
    sinden_retroarchkeymap['44']='comma'
    sinden_retroarchkeymap['45']='minus'
    sinden_retroarchkeymap['46']='period'
    sinden_retroarchkeymap['48']='num0'
    sinden_retroarchkeymap['49']='num1'
    sinden_retroarchkeymap['50']='num2'
    sinden_retroarchkeymap['51']='num3'
    sinden_retroarchkeymap['52']='num4'
    sinden_retroarchkeymap['53']='num5'
    sinden_retroarchkeymap['54']='num6'
    sinden_retroarchkeymap['55']='num7'
    sinden_retroarchkeymap['56']='num8'
    sinden_retroarchkeymap['57']='num9'
    sinden_retroarchkeymap['97']='a'
    sinden_retroarchkeymap['98']='b'
    sinden_retroarchkeymap['99']='c'
    sinden_retroarchkeymap['100']='d'
    sinden_retroarchkeymap['101']='e'
    sinden_retroarchkeymap['102']='f'
    sinden_retroarchkeymap['103']='g'
    sinden_retroarchkeymap['104']='h'
    sinden_retroarchkeymap['105']='i'
    sinden_retroarchkeymap['106']='j'
    sinden_retroarchkeymap['107']='k'
    sinden_retroarchkeymap['108']='l'
    sinden_retroarchkeymap['109']='m'
    sinden_retroarchkeymap['110']='n'
    sinden_retroarchkeymap['111']='o'
    sinden_retroarchkeymap['112']='p'
    sinden_retroarchkeymap['113']='q'
    sinden_retroarchkeymap['114']='r'
    sinden_retroarchkeymap['115']='s'
    sinden_retroarchkeymap['116']='t'
    sinden_retroarchkeymap['117']='u'
    sinden_retroarchkeymap['118']='v'
    sinden_retroarchkeymap['119']='w'
    sinden_retroarchkeymap['120']='x'
    sinden_retroarchkeymap['121']='y'
    sinden_retroarchkeymap['122']='z'
    sinden_retroarchkeymap["1073741903"]="right"
    sinden_retroarchkeymap["1073741904"]="left"
    sinden_retroarchkeymap["1073741905"]="down"
    sinden_retroarchkeymap["1073741906"]="up"
    sinden_retroarchkeymap['1073741882']='f1'
    sinden_retroarchkeymap['1073741883']='f2'
    sinden_retroarchkeymap['1073741884']='f3'
    sinden_retroarchkeymap['1073741885']='f4'
    sinden_retroarchkeymap['1073741886']='f5'
    sinden_retroarchkeymap['1073741887']='f6'
    sinden_retroarchkeymap['1073741888']='f7'
    sinden_retroarchkeymap['1073741889']='f8'
    sinden_retroarchkeymap['1073741890']='f9'
    sinden_retroarchkeymap['1073741891']='f10'
    sinden_retroarchkeymap['1073741892']='f11'
    sinden_retroarchkeymap['1073741893']='f12'
    sinden_retroarchkeymap['1073742050']='alt'
}

function onstart_sinden_keyboard2() {
    onstart_sinden_keyboard
}

function onstart_sinden_keyboard3() {
    onstart_sinden_keyboard
}

# Stores the configuration key for a given ES input name
function map_sinden_keyboard() {
    local input_name="$1"
    local input_type="$2"
    local input_id="$3"
    local input_value="$4"
    local player_id="${5:-1}"

    local key=''

    local keys
    case "$input_name" in
        up)
            retroarch_gun_key='gun_dpad_up'
            sinden_key='ButtonUp'
            ;;
        down)
            retroarch_gun_key='gun_dpad_down'
            sinden_key='ButtonDown'
            ;;
        left)
            retroarch_gun_key='gun_dpad_left'
            sinden_key='ButtonLeft'
            ;;
        right)
            retroarch_gun_key='gun_dpad_right'
            sinden_key='ButtonRight'
            ;;
        a)
            retroarch_gun_key='gun_aux_a'
            sinden_key='ButtonFrontLeft'
            ;;
        b)
            retroarch_gun_key='gun_aux_b'
            sinden_key='ButtonRearLeft'
            ;;
        start)
            retroarch_gun_key='gun_start'
            sinden_key='ButtonFrontRight'
            ;;
        select)
            retroarch_gun_key='gun_select'
            sinden_key='ButtonRearRight'
            ;;
        *)
            return
            ;;
    esac

    local sinden_value=${sinden_keymap[$input_id]}
    local retroarch_value=${sinden_retroarchkeymap[$input_id]}

    local config_suffix
    if [ "$player_id" != '1' ]; then
        config_suffix=$player_id
    fi

    if [ -n "$sinden_value" ]; then
        xmlstarlet ed --inplace \
            --update "/configuration/appSettings/add[@key=\"$sinden_key\"]/@value" -v "$sinden_value" \
            --update "/configuration/appSettings/add[@key=\"${sinden_key}Offscreen\"]/@value" -v "$sinden_value" \
            "$sinden_dir/Player$player_id/LightgunMono${config_suffix}.exe.config"

        iniSet "input_player${player_id}_${retroarch_gun_key}" "$retroarch_value"
    fi
}

function map_sinden_keyboard2() {
    map_sinden_keyboard "${@}" 2
}

function map_sinden_keyboard3() {
    map_sinden_keyboard "${@}" 3
}
