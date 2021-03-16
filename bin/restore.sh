#!/bin/bash

##############
# Restore SD card
##############

set -ex

usage() {
  echo "usage: $0 <device>"
  exit 1
}

restore_file() {
  partition=$1
  device=$2

  gunzip --stdout ../backups/current/sd-retropie-$partition.iso.gz | sudo dd bs=4M of=$device
}

restore() {
  restore_file boot "$device"
  restore_file core "$device"
}

if [[ $# -ne 1 ]]; then
  usage
fi

restore
