#!/bin/bash

set -ex

# The torrent ID
id=

usage() {
  echo "usage: $0 <torrent file> <torrent filter>"
  exit 1
}

add() {
  torrent_file="$1"

  transmission-remote -t all --remove
  transmission-remote --start-paused -a "$torrent_file"
}

lookup_id() {
  id=$(transmission-remote --list | grep -oE "^ +[0-9]" | tr -d ' ')
}

filter() {
  torrent_filter="$1"

  select_files=$(transmission-remote -t $id --files | grep -F -f "$torrent_filter" | grep -oE "^ +[0-9]+" | tr -d " " | tr '\n' ',' | sed 's/,*$//g')
  transmission-remote -t $id --no-get all
  transmission-remote -t $id --get $select_files
}

start() {
  transmission-remote -t $id --start
}

wait_until_done() {
  while ! transmission-remote -t $id --info | grep "Percent Done: 100%" > /dev/null; do
    transmission-remote -t $id --info | grep -A 10 TRANSFER
    sleep 10
  done
}

cleanup() {
  transmission-remote -t all --remove
}

main() {
  torrent_file="$1"
  torrent_filter="$2"

  cleanup
  add "$torrent_file"
  lookup_id
  filter "$torrent_filter"
  start
  wait_until_done
  cleanup
}

if [[ $# -ne 2 ]]; then
  usage
fi

main "$@"
