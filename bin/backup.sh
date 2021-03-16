#!/bin/bash

##############
# Backup SD card
##############

set -ex

usage() {
  echo "usage: $0 <core|boot> <device>"
  exit 1
}

backup() {
  partition=$1
  device=$2

  sudo dd bs=4M if=$device | gzip | dd bs=4M of=../backups/sd-retropie-$partition.iso
}

if [[ $# -ne 2 ]]; then
  usage
fi

partition=$1
device=$2
backup $partition $device
