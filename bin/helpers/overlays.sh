##############
# Overlays
##############

# Generates a Retroarch overlay configuration at the given path with the given
# overlay image
create_overlay_config() {
  local path=$1
  local overlay_filename=$2

  echo "Overlaying $path with $overlay_filename"
  cat > "$path" <<EOF
#include "$retroarch_base_dir/overlay/base.cfg"
overlay0_overlay = "$overlay_filename"
EOF
}

# Outlines that gameplay area for an existing overlay image in order to be
# compatible with certain lightgun controllers like Sinden.
# 
# This allows us to continue to use consistent overlay sources between all
# games by just dynamically generated compatible lightgun overlays.
outline_overlay_image() {
  local source_file="$1"
  local target_file="$2"

  # Formatting
  local width=$(setting '.overlays.lightgun_border.width')
  local color=$(setting '.overlays.lightgun_border.color')
  local fill=$(setting '.overlays.lightgun_border.fill')
  local brightness=$(setting '.overlays.lightgun_border.brightness // 1.0')
  
  # Coordinates
  local left=0
  local right=0
  local top=0
  local bottom=0

  python3 "$bin_dir/tools/outline-overlay.py" "$source_file" "$target_file" \
    --left "$left" --right "$right" --top "$top" --bottom "$bottom" --width "$width" \
    --color "$color" --fill "${fill:-true}" --brightness "$brightness"
}
