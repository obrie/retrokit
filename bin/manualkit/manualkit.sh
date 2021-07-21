#!/bin/bash

runcommand_pid=$(pgrep -f runcommand.sh | sort | tail -n 1)
emulator_pid=$(pstree -T -p $runcommand_pid | grep -o "([[:digit:]]*)" | grep -o "[[:digit:]]*" | tail -n 1)

manual_images_dir='/tmp/retrokit-manual'
vlc_port=1250

start() {
  local manual_path=$1

  # Create directory
  mkdir -p "$manual_images_dir"
  rm -rf "$manual_images_dir"/*

  # Generate the first image so we can get it on the screen while we're converting
  # the rest of the manual
  gs -dSAFER -dNOPAUSE -dBATCH -dJPEGQ=95 -sDEVICE=jpeg -sOutputFile="$manual_images_dir/front.jpg" -dLastPage=1 "$manual_path"

  run &

  # Suspend emulator
  kill -STOP "$emulator_pid"

  # Generate images
  gs -dSAFER -dNOPAUSE -dBATCH -dJPEGQ=95 -sDEVICE=jpeg -sOutputFile="$manual_images_dir/page-%03d.jpg" -dFirstPage=2 "$manual_path"

  # Generate m3u
  while read image_path; do
    execute "enqueue $image_path"
  done < <(ls "$manual_images_dir"/page-*)
}

run() {
  # Un-suspend emulator when the process exits (i.e. VLC is no longer running)
  trap 'shutdown' EXIT

  # Ensure no other vlc running
  killall vlc

  # Run VLC with the first page
  vlc -I rc --rc-host=localhost:$vlc_port --play-and-pause --no-video-title-show --no-osd --fbdev /dev/tty1 "$manual_images_dir/front.jpg"
}

execute() {
  local command=$1

  # Send command to manual
  echo "$command" | nc -q 0 localhost $vlc_port

  # Resume emulator when quitting
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
    start "${@:2}"
  elif pgrep -f vlc; then
    execute "$command"
  fi
}

main "$@"
