#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

restore_globals() {
  restore '/opt/retropie/configs/all/retroarch-core-options.cfg'
}

"${@:1}"
