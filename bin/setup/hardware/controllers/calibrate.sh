#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../../common.sh"

# Reference: https://retropie.org.uk/forum/topic/28693/a-workaround-for-the-northwest-drift-
setup_module_id='hardware/controllers/calibrate'
setup_module_desc='Calibrates the axis midpoint using udev rules (avoids NW drift)'

# Script template
script_start="import evdev
from evdev import ecodes
device = evdev.InputDevice('%E{DEVNAME}')"
script_end="
device.write(ecodes.EV_SYN, 0, 0)
device.close()"

depends() {
  sudo pip3 install evdev~=1.6
}

configure() {
  local rules=()

  while IFS=$field_delim read controller_name controller_id axis_config; do
    local script=$script_start

    # Add a write command for each axis code we need to calibrate
    while IFS== read axis_event_code axis_midpoint; do
      script="$script"$'\n'"device.write(ecodes.EV_ABS, ecodes.$axis_event_code, $axis_midpoint)"
    done < <(echo "$axis_config" | tr ',' '\n')

    # Convert the script to a one-liner
    script="$script$script_end"
    script="${script//$'\n'/; }"

    # Add rule for this controller
    local rule='SUBSYSTEM=="input", KERNEL=="event*", ACTION=="add", '
    if [ -n "$controller_id" ]; then
      # Add filter on controller id
      local vendor_id_hex="${controller_id:10:2}${controller_id:8:2}"
      local product_id_hex="${controller_id:18:2}${controller_id:16:2}"
      rule+='ATTRS{idVendor}=="'"$vendor_id_hex"'", ENV{idProduct}=="'"$product_id_hex"'"'
    else
      # Add filter on controller name
      rule+='ATTRS{name}=="'"$controller_name"'"'
    fi
    rule+=', RUN+="/usr/bin/python3 -c \"'"$script"'\""'

    rules+=("$rule")
  done < <(setting '.hardware.controllers.inputs[] | select(.axis) | [.name, .id, ([.axis | to_entries[] | [.key, .value | tostring] | join("=")] | join(","))] | join("'$field_delim'")')

  # Write the udev rule
  if [ ${#rules[@]} -gt 0 ]; then
    echo "${rules[@]}" | sudo tee /etc/udev/rules.d/99-joystick.rules >/dev/null

    # Reload the configuration (reboot still required)
    sudo udevadm control --reload
  fi
}

restore() {
  sudo rm -fv /etc/udev/rules.d/99-joystick.rules
  sudo udevadm control --reload
}

setup "${@}"
