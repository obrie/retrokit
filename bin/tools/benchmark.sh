#!/bin/bash

##############
# Benchmark Overclocking
##############

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

usage() {
  echo "usage: $0 <pre|post>"
  exit 1
}

run() {
  local mode=$1

  sysbench --test=cpu --num-threads=4 run > $tmp_dir/$mode-benchmark.txt
  cat $tmp_dir/$mode-benchmark.txt
  vcgencmd measure_temp
}

if [[ $# -ne 1 ]]; then
  usage
fi

mode=$1
run $mode
