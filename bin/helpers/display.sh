##############
# Display helpers
##############

get_screen_dimensions() {
  if [ -n "$DISPLAY" ]; then
    # Source: https://superuser.com/a/1207339
    xrandr --current | sed -n 's/.* connected [a-z ]*\([0-9]\+\)x\([0-9]\+\)+.*/\1x\2/p'
  else
    # Assuming running on Raspberry Pi
    local vsize_file="/sys/class/graphics/fb0/virtual_size"
    if [ -f "$vsize_file" ]; then
      cat "$vsize_file" | tr , x
    else
      fbset -s | grep -oE '[0-9]+x[0-9]+'
    fi
  fi
}
