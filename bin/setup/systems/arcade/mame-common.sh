##############
# MAME file management helpers
##############

__find_latest_mame_support_file() {
  local prefix=$1
  local latest_path=$(download 'https://archive.org/download/mame-support/mame-support_files.xml' | grep -oE "Support/.*${prefix}[0-9]+\.zip")
  echo "https://archive.org/download/mame-support/$latest_path"
}
