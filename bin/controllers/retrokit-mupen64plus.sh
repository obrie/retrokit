#!/usr/bin/env bash

function onstart_retrokit-mupen64plus_keyboard() {
    onstart_mupen64plus_joystick

    # SDL codes from https://wiki.libsdl.org/SDLKeycodeLookup
    declare -Ag keymap
    keymap['1073741881']='301' # SDLK_CAPSLOCK
    keymap['1073741882']='282' # SDLK_F1
    keymap['1073741883']='283' # SDLK_F2
    keymap['1073741884']='284' # SDLK_F3
    keymap['1073741885']='285' # SDLK_F4
    keymap['1073741886']='286' # SDLK_F5
    keymap['1073741887']='287' # SDLK_F6
    keymap['1073741888']='288' # SDLK_F7
    keymap['1073741889']='289' # SDLK_F8
    keymap['1073741890']='290' # SDLK_F9
    keymap['1073741891']='291' # SDLK_F10
    keymap['1073741892']='292' # SDLK_F11
    keymap['1073741893']='293' # SDLK_F12
    keymap['1073741894']='316' # SDLK_PRINT
    keymap['1073741895']='302' # SDLK_SCROLLOCK
    keymap['1073741896']='19' # SDLK_PAUSE
    keymap['1073741897']='277' # SDLK_INSERT
    keymap['1073741898']='278' # SDLK_HOME
    keymap['1073741899']='280' # SDLK_PAGEUP
    keymap['1073741901']='279' # SDLK_END
    keymap['1073741902']='281' # SDLK_PAGEDOWN
    keymap['1073741903']='275' # SDLK_RIGHT
    keymap['1073741904']='276' # SDLK_LEFT
    keymap['1073741905']='274' # SDLK_DOWN
    keymap['1073741906']='273' # SDLK_UP
    keymap['1073741907']='300' # SDLK_NUMLOCK
    keymap['1073741910']='269' # SDLK_KP_MINUS
    keymap['1073741911']='270' # SDLK_KP_PLUS
    keymap['1073741912']='271' # SDLK_KP_ENTER
    keymap['1073741913']='257' # SDLK_KP1
    keymap['1073741914']='258' # SDLK_KP2
    keymap['1073741915']='259' # SDLK_KP3
    keymap['1073741916']='260' # SDLK_KP4
    keymap['1073741917']='261' # SDLK_KP5
    keymap['1073741918']='262' # SDLK_KP6
    keymap['1073741919']='263' # SDLK_KP7
    keymap['1073741920']='264' # SDLK_KP8
    keymap['1073741921']='265' # SDLK_KP9
    keymap['1073741922']='256' # SDLK_KP0
    keymap['1073741923']='266' # SDLK_KP_PERIOD
    keymap['1073741927']='272' # SDLK_KP_EQUALS
    keymap['1073742048']='306' # SDLK_LCTRL
    keymap['1073742049']='304' # SDLK_LSHIFT
    keymap['1073742050']='308' # SDLK_LALT
    keymap['1073742052']='305' # SDLK_RCTRL
    keymap['1073742053']='303' # SDLK_RSHIFT
    keymap['1073742054']='307' # SDLK_RALT
}

function map_retrokit-mupen64plus_keyboard() {
    local input_name="$1"
    local input_type="$2"
    local input_id="$3"
    local input_value="$4"

    local keys
    local dir
    case "$input_name" in
        up)
            keys=("DPad U")
            dir=("Up")
            ;;
        down)
            keys=("DPad D")
            dir=("Down")
            ;;
        left)
            keys=("DPad L")
            dir=("Left")
            ;;
        right)
            keys=("DPad R")
            dir=("Right")
            ;;
        b)
            keys=("A Button")
            ;;
        y)
            keys=("B Button")
            ;;
        a)
            keys=("C Button D")
            ;;
        x)
            keys=("C Button U")
            ;;
        leftbottom|leftshoulder)
            keys=("L Trig")
            ;;
        rightbottom|rightshoulder)
            keys=("R Trig")
            ;;
        lefttop|lefttrigger)
            keys=("Z Trig")
            ;;
        start)
            keys=("Start")
            ;;
        leftanalogleft)
            keys=("X Axis")
            dir=("Left")
            ;;
        leftanalogright)
            keys=("X Axis")
            dir=("Right")
            ;;
        leftanalogup)
            keys=("Y Axis")
            dir=("Up")
            ;;
        leftanalogdown)
            keys=("Y Axis")
            dir=("Down")
            ;;
        rightanalogleft)
            keys=("C Button L")
            dir=("Left")
            ;;
        rightanalogright)
            keys=("C Button R")
            dir=("Right")
            ;;
        rightanalogup)
            keys=("C Button U")
            dir=("Up")
            ;;
        rightanalogdown)
            keys=("C Button D")
            dir=("Down")
            ;;
        leftthumb)
            keys=("Mempak switch")
            ;;
        rightthumb)
            keys=("Rumblepak switch")
            ;;
        *)
            return
            ;;
    esac

    local key
    local value
    for key in "${keys[@]}"; do
        # read key value. Axis takes two key/axis values.
        iniGet "$key"

        local sdl_id
        if [ "$input_id" -le 127 ]; then
            sdl_id=$input_id
        else
            sdl_id=${keymap[$input_id]}
        fi

        if [[ "$key" == *Axis* ]]; then
            if   [[ "$ini_value" == *\(* ]]; then
                value="${ini_value}${sdl_id})"
            elif [[ "$ini_value" == *\)* ]]; then
                value="key(${sdl_id},${ini_value}"
            elif [[ "$dir" == "Up" || "$dir" == "Left" ]]; then
                value="key(${sdl_id},"
            elif [[ "$dir" == "Right" || "$dir" == "Down" ]]; then
                value="${sdl_id})"
            fi
        else
            value="key(${sdl_id}) ${ini_value}"
        fi

        iniSet "$key" "$value"
    done
}

function onend_retrokit-mupen64plus_keyboard() {
    local bind
    local axis
    local axis_neg
    local axis_pos
    for axis in "X Axis" "Y Axis"; do
        if [[ "$axis" == *X* ]]; then
            axis_neg="DPad L"
            axis_pos="DPad R"
        else
            axis_neg="DPad U"
            axis_pos="DPad D"
        fi

        # analog stick sanity check
        # replace Axis values with DPAD values if there is no Axis
        # device setup
        if ! grep -q "$axis" /tmp/mp64tempconfig.cfg ; then
            iniGet "${axis_neg}"
            bind=${ini_value//)/,}
            iniGet "${axis_pos}"
            ini_value=${ini_value//key(/}
            bind="${bind}${ini_value}"
            iniSet "$axis" "$bind"
            iniDel "${axis_neg}"
            iniDel "${axis_pos}"
        fi
    done

    onend_mupen64plus_joystick
}
