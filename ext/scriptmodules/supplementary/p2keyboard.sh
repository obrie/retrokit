#!/usr/bin/env bash

rp_module_id="p2keyboard"
rp_module_desc="Configure Player 2+ on your keyboard"
rp_module_section="exp"

function configure_p2keyboard() {
    [[ "$md_mode" == "remove" ]] && return

    local file="p2keyboard"
    local name="Multiplayer Keyboards"
    local desc="Configure keyboard controls for Players 2, 3, etc."

    local rpdir="$home/RetroPie/retropiemenu"
    touch "$rpdir/$file.rp"
    chown $user:$user "$rpdir/$file.rp"

    # Add retrokit to the retropie system
    local function
    for function in $(compgen -A function _add_rom_); do
        "$function" "retropie" "RetroPie" "$file.rp" "$name" "$desc" ""
    done
}

function remove_p2keyboard() {
    rm -fv \
        "$home/RetroPie/retropiemenu/p2keyboard.rp"

    # Remove menu item
    if [ -f "$home/.emulationstation/gamelists/retropie/gamelist.xml" ]; then
        xmlstarlet ed --inplace -d '/gameList/game[name="Multiplayer Keyboards"]' "$home/.emulationstation/gamelists/retropie/gamelist.xml"
    fi
}

# Main menu
function gui_p2keyboard() {
    while true; do
        local cmd=(dialog --colors --backtitle "$__backtitle" --menu "Multiplayer Keyboard Config" 22 85 16)
        local options=(
            "2" "Configure Player 2"
            "3" "Configure Player 3"
            "4" "Configure Player 4"
        )
        local choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
        if [[ -n "$choice" ]]; then
            _gui_configure_p2keyboard "$choice"
        else
            break
        fi
    done
}

function _gui_configure_p2keyboard() {
    local player_id=$1

    # SDL codes from https://wiki.libsdl.org/SDLKeycodeLookup
    # 
    # This is a subset of what's usually offered in EmulationStation as it's
    # just what we can detect in bash.
    declare -A keymap
    keymap[' ']='32'
    keymap["'"]='39'
    keymap['*']='42'
    keymap['+']='43'
    keymap[',']='44'
    keymap['-']='45'
    keymap['.']='46'
    keymap['/']='47'
    keymap['0']='48'
    keymap['1']='49'
    keymap['2']='50'
    keymap['3']='51'
    keymap['4']='52'
    keymap['5']='53'
    keymap['6']='54'
    keymap['7']='55'
    keymap['8']='56'
    keymap['9']='57'
    keymap[';']='59'
    keymap['=']='61'
    keymap['[']='91'
    keymap['\\']='92'
    keymap[']']='93'
    keymap['`']='96'
    keymap['a']='97'
    keymap['b']='98'
    keymap['c']='99'
    keymap['d']='100'
    keymap['e']='101'
    keymap['f']='102'
    keymap['g']='103'
    keymap['h']='104'
    keymap['i']='105'
    keymap['j']='106'
    keymap['k']='107'
    keymap['l']='108'
    keymap['m']='109'
    keymap['n']='110'
    keymap['o']='111'
    keymap['p']='112'
    keymap['q']='113'
    keymap['r']='114'
    keymap['s']='115'
    keymap['t']='116'
    keymap['u']='117'
    keymap['v']='118'
    keymap['w']='119'
    keymap['x']='120'
    keymap['y']='121'
    keymap['z']='122'
    keymap[$'\t']='9'
    keymap[$'\n']='13'
    keymap[$'\e[1~']='1073741898' # home
    keymap[$'\e[2~']='1073741897' # insert
    keymap[$'\e[3~']='127' # del
    keymap[$'\e[4~']='1073741901' # end
    keymap[$'\e[5~']='1073741899' # pageup
    keymap[$'\e[6~']='1073741902' # pagedown
    keymap[$'\e[11~']='1073741882' # f1
    keymap[$'\e[OP']='1073741882' # f1
    keymap[$'\e[12~']='1073741883' # f2
    keymap[$'\e[OQ']='1073741883' # f2
    keymap[$'\e[13~']='1073741884' # f3
    keymap[$'\e[OR']='1073741884' # f3
    keymap[$'\e[14~']='1073741885' # f4
    keymap[$'\e[OS']='1073741885' # f4
    keymap[$'\e[15~']='1073741886' # f5
    keymap[$'\e[17~']='1073741887' # f6
    keymap[$'\e[18~']='1073741888' # f7
    keymap[$'\e[19~']='1073741889' # f8
    keymap[$'\e[20~']='1073741890' # f9
    keymap[$'\e[21~']='1073741891' # f10
    keymap[$'\e[23~']='1073741892' # f11
    keymap[$'\e[24~']='1073741893' # f12
    keymap[$'\e[A']='1073741906' # up
    keymap[$'\e[B']='1073741905' # down
    keymap[$'\e[C']='1073741903' # right
    keymap[$'\e[D']='1073741904' # left

    declare -A keynamemap
    keynamemap[$'\t']='Tab'
    keynamemap[$'\n']='Return'
    keynamemap[$'\e[1~']='Home'
    keynamemap[$'\e[2~']='Insert'
    keynamemap[$'\e[3~']='Del'
    keynamemap[$'\e[4~']='End'
    keynamemap[$'\e[5~']='Page Up'
    keynamemap[$'\e[6~']='Page Down'
    keynamemap[$'\e[11~']='F1'
    keynamemap[$'\e[OP']='F1'
    keynamemap[$'\e[12~']='F2'
    keynamemap[$'\e[OQ']='F2'
    keynamemap[$'\e[13~']='F3'
    keynamemap[$'\e[OR']='F3'
    keynamemap[$'\e[14~']='F4'
    keynamemap[$'\e[OS']='F4'
    keynamemap[$'\e[15~']='F5'
    keynamemap[$'\e[17~']='F6'
    keynamemap[$'\e[18~']='F7'
    keynamemap[$'\e[19~']='F8'
    keynamemap[$'\e[20~']='F9'
    keynamemap[$'\e[21~']='F10'
    keynamemap[$'\e[23~']='F11'
    keynamemap[$'\e[24~']='F12'
    keynamemap[$'\e[A']='Up'
    keynamemap[$'\e[B']='Down'
    keynamemap[$'\e[C']='Right'
    keynamemap[$'\e[D']='Left'

    local button_names=(
        up down left right
        start select
        a b x y
        leftshoulder rightshoulder
        lefttrigger righttrigger
        leftanalogup leftanalogdown leftanalogleft leftanalogright
        rightanalogup rightanalogdown rightanalogleft rightanalogright
    )

    local inputs=''
    local flash_message=''
    declare -A used_sdl_ids

    for button_name in "${button_names[@]}"; do
        dialog --infobox "\n${flash_message}Press key for button \"$button_name\"" 7 50 > /dev/tty
        flash_message=''

        local key=
        if read -sN1 key; then
            while read -sN1 -t 0.001; do
                key+="${REPLY}"
            done
        fi

        if [ "${keymap[$key]}" ]; then
            local sdl_id=${keymap[$key]}

            if [ "${used_sdl_ids[$sdl_id]}" ]; then
                flash_message="Skipped \"$button_name\" since key already used.\n\n"
            else
                used_sdl_ids[$sdl_id]=1
                inputs+="    <input name=\"$button_name\" type=\"key\" id=\"$sdl_id\" value=\"1\" />"$'\n'
                flash_message="Set \"$button_name\" to: ${keynamemap[$key]:-$key}\n\n"
            fi
        else
            flash_message="Skipped \"$button_name\".\n\n"
        fi
    done

    if [ -n "$inputs" ]; then
        file="$home/.emulationstation/es_temporaryinput.cfg"
        cat > "$file" << _EOF_
<?xml version="1.0"?>
<inputList>
  <inputConfig type="keyboard$player_id" deviceName="Keyboard$player_id" deviceGUID="-1">
$inputs
  </inputConfig>
</inputList>
_EOF_

        dialog --infobox "\nGenerating config for player $player_id..." 5 50 > /dev/tty
        su "$user" -c "$rootdir/supplementary/emulationstation/scripts/inputconfiguration.sh" || true
    fi
}
