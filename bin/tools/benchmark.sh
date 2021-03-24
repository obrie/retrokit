#!/bin/bash

##############
# Benchmark Overclocking
##############

set -ex

usage() {
  echo "usage: $0 <pre|post>"
  exit 1
}

run() {
  local mode=$1

  sysbench --test=cpu --num-threads=4 run > /tmp/$mode-benchmark.txt
  cat /tmp/$mode-benchmark.txt
  vcgencmd measure_temp
}

if [[ $# -ne 1 ]]; then
  usage
fi

mode=$1
run $mode
