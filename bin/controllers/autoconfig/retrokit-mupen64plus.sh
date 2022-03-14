#!/usr/bin/env bash

# Add support for:
# * Setting up the keyboard in mupen64plus
# * Overriding joystick configurations to improve axis handling

function onstart_retrokit-mupen64plus_keyboard() {
    onstart_mupen64plus_joystick
    sdl1_map
}

function map_retrokit-mupen64plus_keyboard() {
    local input_name="$1"
    local input_type="$2"
    local input_id="$3"
    local input_value="$4"
    
    local sdl_id=${sdl1_map[$input_id]}

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

function onend_retrokit-mupen64plus_joystick() {
    local file="$configdir/n64/InputAutoCfg.ini"

    # Copy existing config to a temp file for us to modify
    sed -e "/; ${DEVICE_NAME}_START/,/; ${DEVICE_NAME}_END/"'!d' "$file" > /tmp/mp64tempconfig.cfg

    iniConfig " = " "" "/tmp/mp64tempconfig.cfg"

    if [ -s /tmp/mp64tempconfig.cfg ] && getAutoConf 'mupen64plus_combine_axis_and_dpad'; then
        __check_axis_retrokit-mupen64plus 'X Axis' 'DPad L' 'DPad R'
        __check_axis_retrokit-mupen64plus 'Y Axis' 'DPad U' 'DPad D'

        # Abort if old device config cannot be deleted
        sed -i /"${DEVICE_NAME}_START"/,/"${DEVICE_NAME}_END"/d "$file"
        if grep -q "$DEVICE_NAME" "$file" ; then
            rm /tmp/mp64tempconfig.cfg
            return
        fi

        # Append new device config to InputAutoCfg.ini
        cat /tmp/mp64tempconfig.cfg >> "$file"
        rm /tmp/mp64tempconfig.cfg
    fi
}

function __check_axis_retrokit-mupen64plus() {
    local key=$1
    local dpad_key_1=$2
    local dpad_key_2=$3

    iniGet "$key"
    local current_value=$ini_value

    iniGet "$dpad_key_1"
    local dpad_key_1_value=$ini_value

    iniGet "$dpad_key_2"
    local dpad_key_2_value=$ini_value

    # Ensure current value does not contain dpad values and HAT keys *do*
    if [ -n "$ini_value" ] && [[ "$ini_value" != *hat* ]] && [[ "$dpad_key_1_value" == *hat* ]] && [[ "$dpad_key_2_value" == *hat* ]]; then
        local dpad_key_1_input_id=$(echo "$dpad_key_1_value" | grep -oE '[0-9]+')
        local dpad_key_2_input_id=$(echo "$dpad_key_2_value" | grep -oE '[0-9]+')

        if [ "$dpad_key_1_input_id" == "$dpad_key_2_input_id" ]; then
            local dpad_key_1_direction=$(echo "$dpad_key_1_value" | grep -oE 'Up|Down|Left|Right')
            local dpad_key_2_direction=$(echo "$dpad_key_2_value" | grep -oE 'Up|Down|Left|Right')

            # Merge existing axis value with HAT values
            local merged_value="hat($dpad_key_1_input_id $dpad_key_1_direction $dpad_key_2_direction) $current_value"
            iniSet "$key" "$merged_value"
        fi
    fi
}
