##############
# Hooks for invoking other scripts
##############

after_hook() {
  local setupmodule_name=$2

  if [ -z "$SKIP_DEPS" ] && has_setupmodule "$setupmodule_name"; then
    "$bin_dir/setup.sh" "${@}"
  fi
}
