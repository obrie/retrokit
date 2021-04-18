#!/bin/bash

# Maximum time (in seconds) to allow the launching screen to show
# before making it blank
MAX_LOADING_TIME=10

# Clears the screen by writing all black to it
clear_screen() {
  local launching_screen_pid="$1"

  if kill -0 "$launching_screen_pid"; then
    # FBI is still running: just clear the screen
    dd if=/dev/zero of=/dev/fb0 &>/dev/null
  fi
}

# Watches for interrupts to the launching screen
watch_screen() {
  local launching_screen_pid="$1"

  while true; do
    # User has opened runcommand dialog
    if pgrep dialog; then
      clear_screen "$launching_screen_pid"

      # Return to the console frame buffer
      kill -SIGTERM "$launching_screen_pid" || true
      break
    fi

    # Maximum time reached for showing the launching screen
    if [ $SECONDS -ge $MAX_LOADING_TIME ]; then
      clear_screen "$launching_screen_pid"
      break
    fi

    sleep 0.1
  done
}

show_launching_screen() {
  local system="$1"
  local launch_image="/opt/retropie/configs/$system/launching-extended.png"

  if [ -f "$launch_image" ]; then
    # Show launching screen
    fbi -t 0 -1 -noverbose -a /opt/retropie/configs/$system/launching-extended.png </dev/tty &
    local launching_screen_pid=$!

    # Monitor launching screen
    watch_screen $launching_screen_pid &
  fi
}

show_launching_screen "${@}" </dev/null &>/dev/null
