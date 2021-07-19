#!/bin/bash

runcommand_pid=$(pgrep -f runcommand.sh | sort | tail -n 1)
emulator_pid=$(pstree -T -p $runcommand_pid | grep -o "([[:digit:]]*)" | grep -o "[[:digit:]]*" | tail -n 1)

manual_dir='/tmp/retrokit-manual'
playlist_path="$manual_dir/playlist.m3u"
vlc_port=1250

start() {
  # Create directory
  mkdir -p "$manual_dir"
  rm -rf "$manual_dir"/*

  # Generate images
  gs -dSAFER -dNOPAUSE -dBATCH -dJPEGQ=95 -sDEVICE=jpeg -sOutputFile="$manual_dir/%03d.jpg" /home/pi/1080°_Snowboarding_-_1998_-_Nintendo.pdf

  # Generate m3u
  ls "$manual_dir" > "$playlist_path"

  # Suspend emulator
  kill -TSTP "$emulator_pid"

  # Un-suspend emulator on exit
  trap "kill -CONT $emulator_pid" EXIT

  # Ensure no other vlc running
  killall vlc

  # Launch manual
  vlc -I rc --rc-host=localhost:$vlc_port --play-and-pause --no-video-title-show --fbdev /dev/tty1 "$playlist_path"
}

execute() {
  local command=$1

  # Send command to manual
  echo "$command" | nc -q 0 localhost $vlc_port

  # Resume emulator
  if [ "$command" == 'shutdown' ]; then
    shutdown
  fi
}

shutdown() {
  kill -CONT "$emulator_pid"
}

main() {
  local command=$1
  if [ "$command" == 'start' ]; then
    start
  elif pgrep -f vlc; then
    execute "$command"
  fi
}

main "$@"
