#!/bin/bash

system='arcade'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../setup/system-common.sh"

# Path to MAME dats (like gameinit.dat)
dat_path="$HOME/RetroPie/BIOS/mame/history"

# Path to MAME media (like flyers and artwork from https://www.progettosnaps.net/)
mame_media_path="$HOME/.emulationstation/downloaded_media/arcade/mame"
manuals_path="$HOME/.emulationstation/downloaded_media/arcade/manuals/.download"

generate_manuals() {
  mkdir -pv "$manuals_path"

  # Format the gameinit dat to simplify regex patterns
  sed 's/\r$//' "$dat_path/gameinit.dat" > "$tmp_ephemeral_dir/gameinit.dat"

  # Truncate the manuals
  truncate -s0 "$system_config_dir/manuals.tsv"

  while read name; do
    generate_manual "$name" "${@}"
  done < <(romkit_cache_list | jq -r '.name')

  # Sort manuals
  sort -o "$system_config_dir/manuals.tsv" "$system_config_dir/manuals.tsv"
}

generate_manual() {
  local name=$1

  local overwrite='false'
  if [ $# -gt 1 ]; then local "${@:2}"; fi

  # Currently assumes all manuals are in English
  local target_path="$manuals_path/$name (en).pdf"
  if [ -f "$target_path" ] && [ "$overwrite" == 'false' ]; then
    track_manual "$name"
    return
  fi

  local pages=()
  local pdfs=()

  # Find cabinet images
  local cabinet_path="$mame_media_path/cabinets/$name.png"
  if [ -f "$cabinet_path" ]; then
    pages+=("$cabinet_path")
  fi

  # Find flyer images
  local flyer_path="$mame_media_path/flyers/$name.png"
  if [ -f "$flyer_path" ]; then
    pages+=("$flyer_path")
  fi

  # Find instructions artwork
  local artwork_path="$mame_media_path/artwork/$name.zip"
  if [ -f "$artwork_path" ]; then
    mkdir "$tmp_ephemeral_dir/$name"
    while read filename; do
      unzip -joq "$artwork_path" "$filename" -d "$tmp_ephemeral_dir/$name/"
      pages+=("$tmp_ephemeral_dir/$name/$filename")
    done < <(unzip -Z1 "$artwork_path" | sort | grep -E "((inst_cocktail|_inst_|instructions|instcard).*|inst)\.png")
  fi

  # Generate PDF from images
  if [ ${#pages[@]} -gt 0 ]; then
    echo "[$name] Generating images pdf..."
    img2pdf -s 72dpi --engine internal --output "$tmp_ephemeral_dir/images.pdf" "${pages[@]}"
    pdfs+=("$tmp_ephemeral_dir/images.pdf")
  fi

  # Find gameinit.dat instructions
  local gameinit_info=$(awk '/^\$info='"$name"'$/,/end/' <(sed 's/\r$//' "$tmp_ephemeral_dir/gameinit.dat") | tail -n +3 | head -n -2)
  if [ -n "$gameinit_info" ]; then
    echo "[$name] Generating instructions pdf..."
    echo "$gameinit_info" > "$tmp_ephemeral_dir/instructions.txt"
    chromium --headless --disable-gpu --run-all-compositor-stages-before-draw --print-to-pdf-no-header --print-to-pdf="$tmp_ephemeral_dir/instructions.pdf" "$tmp_ephemeral_dir/instructions.txt" 2>/dev/null
    pdfs+=("$tmp_ephemeral_dir/instructions.pdf")
  fi

  # Generate the final pdf
  if [ ${#pdfs[@]} -gt 0 ]; then
    track_manual "$name"

    if [ ${#pdfs[@]} -gt 1 ]; then
      # Merge the pdfs
      gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile="$target_path" "${pdfs[@]}"
    else
      # Copy the individual pdf
      mv "${pdfs[0]}" "$target_path"
    fi
  fi
}

track_manual() {
  echo "$name"$'\t'"en"$'\t'"https://archive.org/download/retrokit-manuals/arcade/arcade-original.zip/$name.pdf" >> "$system_config_dir/manuals.tsv"
}

generate_manuals "${@}"
