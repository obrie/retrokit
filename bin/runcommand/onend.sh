#!/bin/bash

hide_launching_screen() {
  if pgrep fbi; then
    # Clear screen
    dd if=/dev/zero of=/dev/fb0

    # Return to the console frame buffer
    killall -s SIGTERM fbi

    # Make sure the terminal is restored properly just in case fbi isn't shut down properly
    sudo termfix /dev/tty1
    reset
  fi
}

hide_launching_screen &>/dev/null
