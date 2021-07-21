#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

# Emulator processes
runcommand_pid=$(pgrep -f runcommand.sh | sort | tail -n 1)
emulator_pid=$(pstree -T -p $runcommand_pid | grep -o "([[:digit:]]*)" | grep -o "[[:digit:]]*" | tail -n 1)

# ManualKit config
manualkit_socket=/tmp/manualkit.sock

start() {
  local manual_path=$1

  # Un-suspend emulator when the process exits (i.e. manualkit is no longer running)
  trap 'close' EXIT

  # Ensure no other manualkit running
  killall manualkit.py

  # Suspend emulator
  kill -STOP "$emulator_pid"

  # Run manualkit
  python3 "$dir/manualkit.py" "$manual_path" --socket "$manualkit_socket"
}

execute() {
  local command=$1

  # Send command to manualkit
  if [ -f "$manualkit_socket" ]; then
    echo "$command" | nc -q 0 -U "$manualkit_socket"
  fi

  # Resume emulator when quitting
  if [ "$command" == 'close' ]; then
    close
  fi
}

close() {
  kill -CONT "$emulator_pid"
}

main() {
  local command=$1
  if [ "$command" == 'start' ]; then
    start "${@:2}"
  else
    execute "$command"
  fi
}

main "$@"
