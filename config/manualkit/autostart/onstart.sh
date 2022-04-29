#!/bin/bash

sudo python3 /opt/retropie/supplementary/manualkit/cli.py /opt/retropie/configs/all/manualkit.conf --server --profile frontend --track-pid $PPID > $HOME/.emulationstation/manualkit_log.txt 2>&1 &
