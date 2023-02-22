#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

# Path to MAME media (like flyers and artwork from https://www.progettosnaps.net/)
mame_media_dir="$HOME/.emulationstation/downloaded_media/arcade/mame"
manuals_dir="$HOME/.emulationstation/downloaded_media/arcade/manuals/.download"

gameinit_dat_list_url='https://www.progettosnaps.net/gameinit/'
gameinit_dat_url='https://www.progettosnaps.net/download/?tipo=gameinit&file={filename}'
gameinit_download_file="$tmp_dir/arcade/gameinit.dat"

generate_manuals() {
  mkdir -pv "$manuals_dir"

  # Format the gameinit dat to simplify regex patterns
  if [ ! -f "$gameinit_download_file" ]; then
    download_gameinit
  fi
  local gameinit_file=$(mktemp -p "$tmp_ephemeral_dir")
  sed 's/\r$//' "$gameinit_download_file" > "$gameinit_file"

  # Truncate the manuals
  local system_data_file=$(mktemp -p "$tmp_ephemeral_dir")
  jq -c 'del(.manual)' "$data_dir/arcade.json" > "$system_data_file"
  mv "$system_data_file" "$data_dir/arcade.json"

  while read name; do
    generate_manual "$name" "$gameinit_file" "$system_data_file" "${@}"
  done < <(jq -r 'keys[]' "$data_dir/arcade.json")
}

download_gameinit() {
  local filename=$(download "$gameinit_dat_list_url" | grep -oE 'pS_gameinit_[0-9]+.zip')
  if [ -z "$filename" ]; then
    echo '[ERROR] Unable to scrape gameinit.dat filename'
    exit 1
  fi

  local url=$(render_template "$gameinit_dat_url" filename="$filename")
  local gameinit_archive_file=$(mktemp -p "$tmp_ephemeral_dir")
  download "$url" "$gameinit_archive_file"
  unzip -ojq "$gameinit_archive_file" 'dats/gameinit.dat' -d "$tmp_dir/arcade/"
}

generate_manual() {
  local name=$1
  local gameinit_file=$2
  local system_data_file=$3

  local overwrite='false'
  if [ $# -gt 1 ]; then local "${@:2}"; fi

  # Currently assumes all manuals are in English
  local target_pdf="$manuals_dir/$name (en).pdf"
  if [ -f "$target_pdf" ] && [ "$overwrite" == 'false' ]; then
    track_manual "$name"
    return
  fi

  local pages=()
  local pdfs=()

  # Find cabinet images
  local cabinet_image_file="$mame_media_dir/cabinets/$name.png"
  if [ -f "$cabinet_image_file" ]; then
    pages+=("$cabinet_image_file")
  fi

  # Find flyer images
  local flyer_image_file="$mame_media_dir/flyers/$name.png"
  if [ -f "$flyer_image_file" ]; then
    pages+=("$flyer_image_file")
  fi

  # Find instructions artwork
  local artwork_file="$mame_media_dir/artwork/$name.zip"
  if [ -f "$artwork_file" ]; then
    local artwork_extract_dir=$(mktemp -d -p "$tmp_ephemeral_dir")
    while read filename; do
      unzip -ojq "$artwork_file" "$filename" -d "$artwork_extract_dir/"
      pages+=("$artwork_extract_dir/$filename")
    done < <(unzip -Z1 "$artwork_file" | sort | grep -E "((inst_cocktail|_inst_|instructions|instcard).*|inst)\.png")
  fi

  # Generate PDF from images
  if [ ${#pages[@]} -gt 0 ]; then
    echo "[$name] Generating images pdf..."
    local images_pdf_file=$(mktemp -p "$tmp_ephemeral_dir")
    img2pdf -s 72dpi --engine internal --output "$images_pdf_file" "${pages[@]}"
    pdfs+=("$images_pdf_file")
  fi

  # Find gameinit.dat instructions
  local gameinit_info=$(awk '/^\$info='"$name"'$/,/end/' <(sed 's/\r$//' "$gameinit_file") | tail -n +3 | head -n -2)
  if [ -n "$gameinit_info" ]; then
    echo "[$name] Generating instructions pdf..."
    local instructions_txt_file=$(mktemp -p "$tmp_ephemeral_dir" --suffix .txt)
    local instructions_pdf_file=$(mktemp -p "$tmp_ephemeral_dir")
    echo "$gameinit_info" > "$instructions_txt_file"
    chromium --headless --disable-gpu --run-all-compositor-stages-before-draw --print-to-pdf-no-header --print-to-pdf="$instructions_pdf_file" "$instructions_txt_file" 2>/dev/null
    pdfs+=("$instructions_pdf_file")
  fi

  # Generate the final pdf
  if [ ${#pdfs[@]} -gt 0 ]; then
    track_manual "$name"

    if [ ${#pdfs[@]} -gt 1 ]; then
      # Merge the pdfs
      python3 "$bin_dir/tools/pdfmerge.py" "$target_pdf" "${pdfs[@]}"
    else
      # Copy the individual pdf
      mv "${pdfs[0]}" "$target_pdf"
    fi
  fi
}

track_manual() {
  local name=$1
  local manuals_file=$(mktemp -p "$tmp_ephemeral_dir")
  cat <<EOF > "$manuals_file"
    {"name": "$name", "manuals": [{"languages": ["en"], "url": "https://archive.org/download/retrokit-manuals/arcade/arcade-original.zip/$name.pdf"}]}
EOF
  json_merge "$manuals_file" "$data_dir/arcade.json" backup=false
}

generate_manuals "${@}"
