#!/bin/bash

if pgrep fbi; then
  # Clear screen
  dd if=/dev/zero of=/dev/fb0 &>/dev/null

  # Return to the console frame buffer
  killall -s SIGTERM fbi
fi
