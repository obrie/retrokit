#!/usr/bin/env bash

# Path to the supermodel3 configuration where controls are defined
supermodel3_config_file="$configdir/supermodel3/Supermodel.ini"

function check_supermodel3() {
    [[ ! -d "$rootdir/emulators/supermodel3" ]] && return 1
    return 0
}

function onstart_supermodel3() {
    local controller=$1
    local player_id=$2

    getAutoConf supermodel3_hotkey_reset
    _supermodel3_hotkey_reset="${ini_value:-1}"

    if [ -f "$supermodel3_config_file" ]; then
        cp "$supermodel3_config_file" '/tmp/supermodel3-controls.ini'
    else
        cat > '/tmp/supermodel3-controls.ini' <<EOF
InputAnalogGunX = "MOUSE1_XAXIS"
InputAnalogGunX2 = "MOUSE2_XAXIS"
InputAnalogGunY = "MOUSE1_YAXIS"
InputAnalogGunY2 = "MOUSE2_YAXIS"
InputAnalogJoyEvent = "MOUSE1_RIGHT_BUTTON"
InputAnalogJoyTrigger = "MOUSE1_LEFT_BUTTON"
InputAnalogJoyX = "MOUSE1_XAXIS_INV"
InputAnalogJoyY = "MOUSE1_YAXIS_INV"
InputAnalogTriggerLeft = "MOUSE1_LEFT_BUTTON"
InputAnalogTriggerLeft2 = "MOUSE2_LEFT_BUTTON"
InputAnalogTriggerRight = "MOUSE1_RIGHT_BUTTON"
InputAnalogTriggerRight2 = "MOUSE2_RIGHT_BUTTON"
InputGunX = "MOUSE1_XAXIS"
InputGunX2 = "MOUSE2_XAXIS"
InputGunY = "MOUSE1_YAXIS"
InputGunY2 = "MOUSE2_YAXIS"
InputOffscreen = "MOUSE1_RIGHT_BUTTON"
InputOffscreen2 = "MOUSE2_RIGHT_BUTTON"
InputTrigger = "MOUSE1_LEFT_BUTTON"
InputTrigger2 = "MOUSE2_LEFT_BUTTON"
EOF
    fi
    _set_supermodel3_ini '/tmp/supermodel3-controls.ini'

    # Reset inputs for this controller type
    local regex_controller="$controller[^,\"]\+"
    local regex_line
    if [[ "$player_id" == '2' ]]; then
        regex_line="/^[^ ]\+2/"
    fi

    sed -i "${regex_line}s/,$regex_controller//g" '/tmp/supermodel3-controls.ini'
    sed -i "${regex_line}s/$regex_controller,\?//g" '/tmp/supermodel3-controls.ini'
    sed -i 's/^\(Input.*\)NONE/\1/g' '/tmp/supermodel3-controls.ini'

    declare -Ag supermodel3_mapped_inputs
    declare -g supermodel3_hotkey_value=''
}

function _set_supermodel3_ini() {
    iniConfig ' = ' '"' "$1"
}

function onstart_supermodel3_joystick() {
    onstart_supermodel3 JOY

    # Define initial device-specific config
    truncate -s0 /tmp/supermodel3-device-controls.ini
}

function onstart_supermodel3_keyboard() {
    local player_id=$1

    onstart_supermodel3 KEY ${player_id:-1}

    # SDL codes from https://wiki.libsdl.org/SDLKeycodeLookup
    declare -Ag supermodel3_keymap
    # SDL codes from https://wiki.libsdl.org/SDLKeycodeLookup
    supermodel3_keymap["1073741904"]="LEFT"
    supermodel3_keymap["1073741903"]="RIGHT"
    supermodel3_keymap["1073741906"]="UP"
    supermodel3_keymap["1073741905"]="DOWN"
    supermodel3_keymap["13"]="RETURN"
    supermodel3_keymap["1073741912"]="KEYPADENTER"
    supermodel3_keymap["9"]="TAB"
    supermodel3_keymap["1073741897"]="INSERT"
    supermodel3_keymap["127"]="DEL"
    supermodel3_keymap["1073741901"]="END"
    supermodel3_keymap["1073741898"]="HOME"
    supermodel3_keymap["1073742053"]="RIGHTSHIFT"
    supermodel3_keymap["1073742049"]="LEFTSHIFT"
    supermodel3_keymap["1073742048"]="LEFTCTRL"
    supermodel3_keymap["1073742050"]="LEFTALT"
    supermodel3_keymap["32"]="SPACE"
    supermodel3_keymap["27"]="ESCAPE"
    supermodel3_keymap["1073741911"]="KEYPADMINUS"
    supermodel3_keymap["1073741910"]="KEYPADPLUS"
    supermodel3_keymap["1073741882"]="F1"
    supermodel3_keymap["1073741883"]="F2"
    supermodel3_keymap["1073741884"]="F3"
    supermodel3_keymap["1073741885"]="F4"
    supermodel3_keymap["1073741886"]="F5"
    supermodel3_keymap["1073741887"]="F6"
    supermodel3_keymap["1073741888"]="F7"
    supermodel3_keymap["1073741889"]="F8"
    supermodel3_keymap["1073741890"]="F9"
    supermodel3_keymap["1073741891"]="F10"
    supermodel3_keymap["1073741892"]="F11"
    supermodel3_keymap["1073741893"]="F12"
    supermodel3_keymap["48"]="0"
    supermodel3_keymap["49"]="1"
    supermodel3_keymap["50"]="2"
    supermodel3_keymap["51"]="3"
    supermodel3_keymap["52"]="4"
    supermodel3_keymap["53"]="5"
    supermodel3_keymap["54"]="6"
    supermodel3_keymap["55"]="7"
    supermodel3_keymap["56"]="8"
    supermodel3_keymap["57"]="9"
    supermodel3_keymap["1073741899"]="PGUP"
    supermodel3_keymap["1073741902"]="PGDOWN"
    supermodel3_keymap["1073741922"]="KEYPAD0"
    supermodel3_keymap["1073741913"]="KEYPAD1"
    supermodel3_keymap["1073741914"]="KEYPAD2"
    supermodel3_keymap["1073741915"]="KEYPAD3"
    supermodel3_keymap["1073741916"]="KEYPAD4"
    supermodel3_keymap["1073741917"]="KEYPAD5"
    supermodel3_keymap["1073741918"]="KEYPAD6"
    supermodel3_keymap["1073741919"]="KEYPAD7"
    supermodel3_keymap["1073741920"]="KEYPAD8"
    supermodel3_keymap["1073741921"]="KEYPAD9"
    supermodel3_keymap["46"]="PERIOD"
    supermodel3_keymap["8"]="BACKSPACE"
    supermodel3_keymap["42"]="KEYPADMULTIPLY"
    supermodel3_keymap["47"]="KEYPADDIVIDE"
    supermodel3_keymap["96"]="BACKQUOTE"
    supermodel3_keymap["1073741896"]="PAUSE"
    supermodel3_keymap["39"]="QUOTE"
    supermodel3_keymap["44"]="COMMA"
    supermodel3_keymap["45"]="MINUS"
    supermodel3_keymap["47"]="SLASH"
    supermodel3_keymap["59"]="SEMICOLON"
    supermodel3_keymap["61"]="EQUALS"
    supermodel3_keymap["91"]="LEFTBRACKET"
    supermodel3_keymap["92"]="BACKSLASH"
    supermodel3_keymap["93"]="RIGHTBRACKET"
    supermodel3_keymap["1073741923"]="KEYPADPERIOD"
    supermodel3_keymap["1073741927"]="KEYPADEQUALS"
    supermodel3_keymap["1073742052"]="RIGHTCTRL"
    supermodel3_keymap["1073742054"]="RIGHTALT"
    supermodel3_keymap["97"]="A"
    supermodel3_keymap["98"]="B"
    supermodel3_keymap["99"]="C"
    supermodel3_keymap["100"]="D"
    supermodel3_keymap["101"]="E"
    supermodel3_keymap["102"]="F"
    supermodel3_keymap["103"]="G"
    supermodel3_keymap["104"]="H"
    supermodel3_keymap["105"]="I"
    supermodel3_keymap["106"]="J"
    supermodel3_keymap["107"]="K"
    supermodel3_keymap["108"]="L"
    supermodel3_keymap["109"]="M"
    supermodel3_keymap["110"]="N"
    supermodel3_keymap["111"]="O"
    supermodel3_keymap["112"]="P"
    supermodel3_keymap["113"]="Q"
    supermodel3_keymap["114"]="R"
    supermodel3_keymap["115"]="S"
    supermodel3_keymap["116"]="T"
    supermodel3_keymap["117"]="U"
    supermodel3_keymap["118"]="V"
    supermodel3_keymap["119"]="W"
    supermodel3_keymap["120"]="X"
    supermodel3_keymap["121"]="Y"
    supermodel3_keymap["122"]="Z"
}

function onstart_supermodel3_keyboard2() {
    onstart_supermodel3_keyboard 2
}

# Generates the configuration key for a given ES input name
function _get_supermodel3_config_keys() {
    local input_name=$1
    local key=''

    case "$input_name" in
        up)
            keys=("InputAccelerator" "InputJoyUp{,2}" "InputAnalogGunUp{,2}" "InputAnalogJoyUp{,2}" "InputFishingRodUp" "InputGunUp{,2}" "InputSkiUp" "InputMagicalLeverUp1")
            ;;
        down)
            keys=("InputBrake" "InputJoyDown{,2}" "InputAnalogGunDown{,2}" "InputAnalogJoyDown{,2}" "InputFishingRodDown" "InputGunDown{,2}" "InputSkiDown" "InputMagicalLeverDown1")
            ;;
        left)
            keys=("InputJoyLeft{,2}" "InputAnalogGunLeft{,2}" "InputAnalogJoyLeft{,2}" "InputFishingRodLeft" "InputGunLeft{,2}" "InputSkiLeft" "InputSteeringLeft")
            ;;
        right)
            keys=("InputJoyRight{,2}" "InputAnalogGunRight{,2}" "InputAnalogJoyRight{,2}" "InputFishingRodRight" "InputGunRight{,2}" "InputSkiRight" "InputSteeringRight")
            ;;
        b)
            keys=("InputAnalogTriggerLeft" "InputAnalogJoyTrigger{,}" "InputFishingCast" "InputMagicalPedal{1,2}" "InputPunch{,2}" "InputShift" "InputShortPass{,2}" "InputSkiPollLeft" "InputTrigger{,2}" "InputTwinJoyJump" "InputViewChange" "InputVR1")
            ;;
        y)
            keys=("InputCharge" "InputGuard{,2}" "InputMusicSelect" "InputShoot{,2}" "InputSkiSelect1" "InputVR3")
            ;;
        a)
            keys=("InputAnalogTriggerRight" "InputAnalogJoyTrigger2{,}" "InputAnalogJoyEvent" "InputBeat" "InputFishingSelect" "InputHandBrake" "InputKick{,2}" "InputLongPass{,2}" "InputOffscreen{,2}" "InputRearBrake" "InputSkiPollRight" "InputTwinJoyCrouch" "InputVR2")
            ;;
        x)
            keys=("InputEscape{,2}" "InputJump" "InputSkiSelect2")
            ;;
        leftbottom|leftshoulder)
            keys=("InputGearShift1" "InputSkiSelect3" "InputTwinJoyShot1")
            ;;
        rightbottom|rightshoulder)
            keys=("InputGearShift2" "InputTwinJoyShot2")
            ;;
        lefttop|lefttrigger)
            keys=("InputGearShift3" "InputTwinJoyTurbo1")
            ;;
        righttop|righttrigger)
            keys=("InputGearShift4" "InputTwinJoyTurbo2")
            ;;
        start)
            keys=("InputStart{1,2}")
            ;;
        select)
            keys=("InputCoin{1,2}")
            ;;
        leftanalogleft)
            keys=("InputTwinJoyStrafeLeft" "InputAnalogGunLeft{,2}" "InputAnalogJoyLeft{,2}" "InputFishingRodLeft" "InputGunLeft{,2}" "InputSkiLeft" "InputSteeringLeft")
            ;;
        leftanalogright)
            keys=("InputTwinJoyStrafeRight" "InputAnalogGunRight{,2}" "InputAnalogJoyRight{,2}" "InputFishingRodRight" "InputGunRight{,2}" "InputSkiRight" "InputSteeringRight")
            ;;
        leftanalogup)
            keys=("InputTwinJoyForward" "InputAccelerator" "InputAnalogGunUp{,2}" "InputAnalogJoyUp{,2}" "InputFishingRodUp" "InputGunUp{,2}" "InputSkiUp" "InputMagicalLeverUp1")
            ;;
        leftanalogdown)
            keys=("InputTwinJoyReverse" "InputBrake" "InputAnalogGunDown{,2}" "InputAnalogJoyDown{,2}" "InputFishingRodDown" "InputGunDown{,2}" "InputSkiDown" "InputMagicalLeverDown1")
            ;;
        rightanalogleft)
            keys=("InputTwinJoyTurnLeft" "InputFishingStickLeft")
            ;;
        rightanalogright)
            keys=("InputTwinJoyTurnRight" "InputFishingStickRight")
            ;;
        rightanalogup)
            keys=("InputFishingStickUp" "InputGearShiftUp")
            ;;
        rightanalogdown)
            keys=("InputFishingStickDown" "InputGearShiftDown")
            ;;
        leftthumb)
            keys=("InputFishingTension")
            ;;
        rightthumb)
            keys=("InputFishingReel" "InputGearShiftN")
            ;;
        *)
            return
            ;;
    esac

    echo "${keys[@]}"
}

function map_supermodel3() {
    local input_name=$1
    local keys=$2
    local controller=$3
    local value=$4
    local player_id=$5

    if [ -z "${supermodel3_mapped_inputs["$input_name"]}" ]; then
        supermodel3_mapped_inputs["$input_name"]="$value"
    fi

    # Merge the mapped value with existing ones
    for key in $keys; do
        # Identify the actual input configurations to modify
        local base_input_name=${key%%{*}
        local input_names=()
        if [[ "$key" == *{,}* ]]; then
            if [ "$controller" == 'KEY' ] && [ "$player_id" == '2' ]; then
                continue
            fi

            input_names=("$base_input_name" "$base_input_name")
        elif [[ "$key" == *{1,2}* ]]; then
            input_names=("${base_input_name}1" "${base_input_name}2")
        elif [[ "$key" == *{,2}* ]]; then
            input_names=("${base_input_name}" "${base_input_name}2")
        else
            input_names=("$base_input_name")
        fi

        for input_index in ${!input_names[@]}; do
            local input_name=${input_names[$input_index]}
            local current_player_id=$((input_index+1))
            if [[ -n "$player_id" ]] && [[ "$current_player_id" != "$player_id" ]]; then
                # Not the player id being mapped
                continue
            fi

            local value_prefix
            if [[ "$controller" == 'JOY' ]]; then
                value_prefix="JOY${current_player_id}_"
            else
                value_prefix='KEY_'
            fi

            # Get other values not for this controller/player
            iniGet "$input_name"
            local merged_value=$ini_value
            if [ -n "$merged_value" ]; then
                merged_value+=','
            fi

            # Add in this controller value
            IFS='+' read -r value1 value2 <<< "$value"
            if [ -n "$value2" ]; then
                merged_value+="${value_prefix}${value1}+${value_prefix}${value2}"
            else
                merged_value+="${value_prefix}${value}"
            fi

            iniSet "$input_name" "$merged_value"
        done
    done
}

function map_supermodel3_joystick() {
    # input_id for button => button number
    local input_name=$1
    local input_type=$2
    local input_id=$3
    local input_value=$4

    # Look up the supermodel3 configuration keys this input maps to
    local keys=$(_get_supermodel3_config_keys "$input_name")

    local value
    case "$input_type" in
        hat)
            # Get the button name that's associated with this HAT direction
            declare -A hat_map=([1]="UP" [2]="RIGHT" [4]="DOWN" [8]="LEFT")
            value="POV$((input_id+1))_${hat_map[$input_value]}"
            ;;
        axis)
            declare -A axis_map=([0]="X" [1]="Y" [2]="RX" [3]="RY")
            value=${axis_map[$input_id]}
            [[ -z "$value" ]] && return

            if [[ "$input_value" == '1' ]]; then
                value="${value}AXIS_POS"
            else
                value="${value}AXIS_NEG"
            fi
            ;;
        *)
            value="BUTTON$((input_id+1))"
            ;;
    esac

    if [ -n "$value" ]; then
        if [ "$input_name" == 'hotkeyenable' ]; then
            supermodel3_hotkey_value=$value
        fi

        if [ -n "$keys" ]; then
            _set_supermodel3_ini /tmp/supermodel3-controls.ini
            map_supermodel3 "$input_name" "$keys" JOY "$value"

            # Device-specific config
            _set_supermodel3_ini /tmp/supermodel3-device-controls.ini
            map_supermodel3 "$input_name" "$keys" JOY "$value"
        fi
    fi
}

function map_supermodel3_keyboard() {
    local input_name=$1
    local input_type=$2
    local input_id=$3
    local input_value=$4
    local player_id="${5:-1}"

    # Look up the supermodel3 configuration key this input maps to
    local keys=$(_get_supermodel3_config_keys "$input_name" 1)

    # Find the corresponding advmame key name for the given sdl id
    local value=${supermodel3_keymap[$input_id]}

    if [ -n "$value" ]; then
        if [ "$player_id" != '2' ] && [ "$input_name" == 'hotkeyenable' ]; then
            supermodel3_hotkey_value=$value
        fi

        if [ -n "$keys" ]; then
            map_supermodel3 "$input_name" "$keys" KEY "$value" "$player_id"
        fi
    fi
}

function map_supermodel3_keyboard2() {
    map_supermodel3_keyboard "${@}" 2
}

# Generates the input_map configuration key to use for the supermodel3 UI
function _get_supermodel3_hotkey() {
    local input_name=$1
    local key=''

    case "$input_name" in
        a)
            key="InputUIPause"
            ;;
        b)
            [[ "$_supermodel3_hotkey_reset" == '1' ]] && key="InputUIReset"
            ;;
        x)
            key="InputTestA"
            ;;
        y)
            key="InputTestB"
            ;;
        start)
            key="InputUIExit"
            ;;
        leftbottom|leftshoulder)
            key="InputUILoadState"
            ;;
        rightbottom|rightshoulder)
            key="InputUISaveState"
            ;;
        lefttop|lefttrigger)
            key="InputServiceA"
            ;;
        righttop|righttrigger)
            key="InputServiceB"
            ;;
        *)
            ;;
    esac

    echo "$key"
}

function _onend_supermodel3() {
    local controller=$1

    # If a hotkey was defined, set up all the pairings now
    if [ -n "$supermodel3_hotkey_value" ]; then
        local input_name
        for input_name in "${!supermodel3_mapped_inputs[@]}"; do
            local pair_value=${supermodel3_mapped_inputs[$input_name]}

            # Check if there's a hotkey configuration for this input
            local hotkey=$(_get_supermodel3_hotkey "$input_name")

            if [ -n "$hotkey" ]; then
                _set_supermodel3_ini /tmp/supermodel3-controls.ini
                map_supermodel3 "$input_name" "$hotkey" "$controller" "$supermodel3_hotkey_value+$pair_value" 1

                _set_supermodel3_ini /tmp/supermodel3-device-controls.ini
                map_supermodel3 "$input_name" "$hotkey" "$controller" "$supermodel3_hotkey_value+$pair_value" 1
            fi
        done
    fi

    # Replace empty lines
    sed -i 's/^\(Input.*\)""/\1"NONE"/g' '/tmp/supermodel3-controls.ini'

    mkdir -p "$(dirname "$supermodel3_config_file")"
    mv '/tmp/supermodel3-controls.ini' "$supermodel3_config_file"
}

function onend_supermodel3_joystick() {
    _onend_supermodel3 'JOY'

    # Define a device-specific file in order to support multiple joysticks
    local supermodel3_device_config_file="$configdir/supermodel3/Supermodel-${DEVICE_NAME//[:><?\"\/\\|*]/}.ini"
    cp '/tmp/supermodel3-device-controls.ini' "$supermodel3_device_config_file"
}

function onend_supermodel3_keyboard() {
    _onend_supermodel3 'KEY'
}

function onend_supermodel3_keyboard2() {
    onend_supermodel3_keyboard
}
