#!/bin/bash

hide_launching_screen() {
  if pgrep fbi; then
    # Clear screen
    dd if=/dev/zero of=/dev/fb0

    # Return to the console frame buffer
    killall -s SIGTERM fbi
  fi
}

hide_launching_screen &>/dev/null
