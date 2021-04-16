#!/bin/bash

set -ex

system='pc'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../system-common.sh"

install() {
  download 'https://docs.google.com/spreadsheets/d/1r6kjP_qqLgBeUzXdDtIDXv1TvoysG_7u2Tj7auJsZw4/export?gid=82569470&format=tsv' "$system_tmp_dir/c64_dreams.tsv"
}

uninstall() {
  echo 'No uninstall for c64'
}

"${@}"
