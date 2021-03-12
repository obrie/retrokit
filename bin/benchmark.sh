#!/bin/bash

##############
# Benchmark Overclocking
##############

set -e

# Run before overclock change
sysbench --test=cpu --num-threads=4 run > pre-benchmark.txt
vcgencmd measure_temp

# Run after overclock change
sysbench --test=cpu --num-threads=4 run > post-benchmark.txt
