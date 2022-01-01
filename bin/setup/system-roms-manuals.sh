#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

# Downloads manuals from the given URL(s)
# 
# Manuals that have already been postprocessed will be copied to the
# postprocess path to indicate that no postprocessing is necessary.
download_pdf() {
  local manual_url=$1
  local archive_url=$2
  local download_path=$3
  local postprocess_path=$4

  mkdir -p "$(dirname "$download_path")" "$(dirname "$postprocess_path")"

  # First attempt to download from the archive
  if [ -n "$archive_url" ] && download "$archive_url" "$download_path" max_attempts=1; then
    if [ "$(setting '.manuals.archive.processed')" == 'true' ]; then
      cp "$download_path" "$postprocess_path"
    fi
  else
    # Fall back to the original source of the manual
    if download "$manual_url" "$download_path"; then
      # For non-archive.org manuals, we introduce a sleep here in order to
      # keep site owners happy and not overwhelm their servers
      if [[ "$manual_url" != *archive.org* ]]; then
        sleep 60
      fi
    else
      return 1
    fi
  fi
}

# Combines 1 or more images into a PDF
# 
# This is a lossless conversion except for PNG images which contain alpha channels.
combine_images_to_pdf() {
  local target_path=$1
  local source_path=$2
  local filter_csv=${3:-*}

  # Figure out which paths should be included, making sure that we find files
  # based on the order of the filters specified
  local filtered_paths=()
  while read -r filter; do
    IFS=$'\n' filtered_paths+=($(find "$source_path" -type f -wholename "$source_path/$filter" | sort))
  done < <(echo "$filter_csv" | tr ';' '\n')

  # Remove alpha channel from PNG images as img2pdf cannot handle them
  while read source_path; do
    mogrify -background white -alpha remove -alpha off "$source_path"
  done < <(printf -- '%s\n' "${filtered_paths[@]}" | grep -i .png)

  img2pdf --output "$target_path" "${filtered_paths[@]}"
}

# Converts a downloaded file to a PDF so that all manuals are in a standard
# format for us to work with
convert_to_pdf() {
  local source_path=$1
  local target_path=$2
  local filter_csv=$3

  # Glob expression for picking out images from archives
  local extract_path="$tmp_ephemeral_dir/pdf-extract"

  mkdir -p "$(dirname "$target_path")"

  local extension=${source_path##*.}
  if [[ "$extension" =~ ^(html?|txt)$ ]]; then
    # Print to pdf via chrome
    # 
    # Chromium can't access files in hidden directories, so it needs to be sourced
    # from a different directory
    local chromium_path="$tmp_ephemeral_dir/$(basename "$source_path")"
    cp "$source_path" "$chromium_path"
    chromium --headless --disable-gpu --run-all-compositor-stages-before-draw --print-to-pdf-no-header --print-to-pdf="$target_path" "$chromium_path" 2>/dev/null
    rm "$chromium_path"
  elif [[ "$extension" =~ ^(zip|cbz)$ ]]; then
    # Zip of images -- extract and concatenate into pdf
    rm -rf "$extract_path"
    unzip -j "$source_path" -d "$extract_path"
    combine_images_to_pdf "$target_path" "$extract_path" "$filter_csv"
    rm -rf "$extract_path"
  elif [[ "$extension" =~ ^(rar|cbr)$ ]]; then
    # Rar of images -- extract and concatenate into pdf
    rm -rf "$extract_path"
    unrar e "$source_path" "$extract_path/"
    combine_images_to_pdf "$source_path" "$extract_path" "$filter_csv"
    rm -rf "$extract_path"
  elif [[ "$extension" =~ ^(png|jpe?g)$ ]]; then
    combine_images_to_pdf "$target_path" "$(dirname "$source_path")" "$(basename "$source_path")"
  else
    # No conversion necessary -- copy to the target
    cp "$source_path" "$target_path"
  fi
}

# Runs any configured post-processing on the PDF, including:
# * Rotate
# * Truncate
# * Optimize
# * Compress
postprocess_pdf() {
  local pdf_path=$1 # source
  local target_path=$2
  local pages=$3
  local rotate=${4:-0}
  local pdf_tmp_path="$tmp_ephemeral_dir/postprocess-tmp.pdf"

  # Optimize (always)
  local gsargs=(
    -sDEVICE=pdfwrite
    -dCompatibilityLevel=1.4
    -dNOPAUSE
    -dQUIET
    -dBATCH
    -dAutoRotatePages=/None
    -dOptimize=true
    # color format (to optimize rendering)
    -sProcessColorModel=DeviceRGB
    -sColorConversionStrategy=sRGB
    -sColorConversionStrategyForImages=sRGB
    -dConvertCMYKImagesToRGB=true
    -dConvertImagesToIndexed=true
    # remove unnecessary data (to reduce filesize)
    -dDetectDuplicateImages=true
    -dDoThumbnails=false
    -dCreateJobTicket=false
    -dPreserveEPSInfo=false
    -dPreserveOPIComments=false
    -dPreserveOverprintSettings=false
    -dUCRandBGInfo=/Remove
    # avoid errors
    -dCannotEmbedFontPolicy=/Warning
  )
  if [ -n "$pages" ]; then
    # Truncate
    IFS='-' read first_page last_page <<< "$pages"
    gsargs+=(
      -dFirstPage=$first_page
      -dLastPage=$last_page
    )
  fi

  gs "${gsargs[@]}" -sOutputFile="$pdf_tmp_path" -f "$pdf_path"
  mv "$pdf_tmp_path" "$pdf_path"

  # Compress (if the file is big enough and we're compressing)
  local filesize_threshold=$(setting '.manuals.postprocess.downsample_filesize_threshold // 0')
  local resolution=$(setting '.manuals.postprocess.resolution // "original"')
  if [ $(stat -c%s "$pdf_path") -gt "$filesize_threshold" ] && [ "$resolution" != 'original' ]; then
    local quality_factor=$(setting '.manuals.postprocess.quality_factor')
    local downsample_threshold=$(setting '.manuals.postprocess.downsample_threshold')

    gs "${gsargs[@]}" \
      -sOutputFile="$pdf_tmp_path"
      -dColorImageDownsampleThreshold=$downsample_threshold -dGrayImageDownsampleThreshold=$downsample_threshold -dMonoImageDownsampleThreshold=$downsample_threshold \
      -dColorImageDownsampleType=/Bicubic -dGrayImageDownsampleType=/Bicubic \
      -dDownsampleColorImages=true -dDownsampleGrayImages=true -dDownsampleMonoImages=true \
      -dColorImageResolution=$resolution -dGrayImageResolution=$resolution -dMonoImageResolution=$resolution \
      -c "<< /ColorACSImageDict << /QFactor $quality_factor /Blend 1 /ColorTransform 1 /HSamples [1 1 1 1] /VSamples [1 1 1 1] >> >> setdistillerparams" \
      -c "<< /GrayACSImageDict << /QFactor $quality_factor /Blend 1 /ColorTransform 1 /HSamples [1 1 1 1] /VSamples [1 1 1 1] >> >> setdistillerparams" \
      -c "<< /HWResolution [600 600] >> setpagedevice" \
      -f "$pdf_path"

    # Only use the compressed file if it's actually smaller
    if [ $(stat -c%s "$pdf_tmp_path") -lt $(stat -c%s "$pdf_path") ]; then
      mv "$pdf_tmp_path" "$pdf_path"
    else
      rm "$pdf_tmp_path"
    fi
  fi

  # Rotate
  if [ "$rotate" != '0' ]; then
    mutool draw -R "$rotate" -o "$pdf_path" "$pdf_path"
  fi

  # Copy to target
  cp "$pdf_path" "$target_path"
}

# Lists the manuals to install
list_manuals() {
  if [ "$MANUALKIT_ARCHIVE" == 'true' ]; then
    # We're generating the manualkit archive -- list all manuals for all languages
    cat "$system_config_dir/manuals.tsv" | sed -r 's/^([^\t]+)\t([^\t]+)(.+)$/\1 (\2)\t\1\t\2\3/'
  else
    romkit_cache_list | jq -r 'select(.manual) | [.name, .parent .title // .title, .manual .languages, .manual .url, .manual .options] | @tsv'
  fi
}

install() {
  # Ensure the system has manuals
  if [ ! -f "$system_config_dir/manuals.tsv" ]; then
    echo 'No manuals configured'
    return
  fi

  # Local paths
  local base_path_template=$(setting '.manuals.paths.base')
  local download_path_template=$(setting '.manuals.paths.download')
  local postprocess_path_template=$(setting '.manuals.paths.postprocess')
  local install_path_template=$(setting '.manuals.paths.install')
  local keep_downloads=$(setting '.manuals.keep_downloads')

  # Pre-existing archive to download from
  local archive_url_template=$(setting '.manuals.archive.url')

  declare -A installed_files
  declare -A installed_playlists
  while IFS=$'\t' read -r rom_name parent_title manual_languages manual_url manual_options; do
    # Read processing options
    declare -A options=( [format]= [pages]= [rotate]= [filter]= )
    if [ -n "$manual_options" ]; then
      while IFS='=' read -r option value; do
        options["$option"]=$value
      done < <(echo "$manual_options" | tr ',' '\n')
    fi

    # Fix URLs:
    # * Explicitly escape the character "#" since rom names can have that character
    local manual_url=${manual_url//#/%23}

    # Define template variables
    local manual_url_extension=${manual_url##*.}
    local extension=${options['format']:-$manual_url_extension}
    extension=${extension,,} # lowercase
    local template_variables=(
      system="$system"
      parent_title="$parent_title"
      languages="$manual_languages"
      name="$rom_name"
      extension="$extension"
    )

    # Render local paths
    local download_path=$(render_template "$download_path_template" "${template_variables[@]}")
    local postprocess_path=$(render_template "$postprocess_path_template" "${template_variables[@]}")
    local install_path=$(render_template "$install_path_template" "${template_variables[@]}")

    # Track paths to ensure they don't get deleted
    installed_files["$install_path"]=1
    installed_files["$postprocess_path"]=1
    # Track the downloads (if configured to persist)
    if [ "$keep_downloads" == 'true' ]; then
      installed_files["$download_path"]=1
    fi

    # Download the file
    if [ ! -f "$download_path" ] && [ ! -f "$postprocess_path" ]; then
      local archive_url=$(render_template "$archive_url_template" "${template_variables[@]}")
      if ! download_pdf "$manual_url" "$archive_url" "$download_path" "$postprocess_path"; then
        echo "[$rom_name] Failed to download from $manual_url"
        continue
      fi
    fi

    # Post-process the pdf
    if [ ! -f "$postprocess_path" ]; then
      convert_to_pdf "$download_path" "$tmp_ephemeral_dir/rom.pdf" "${options['filter']}"
      postprocess_pdf "$tmp_ephemeral_dir/rom.pdf" "$postprocess_path" "${options['pages']}" "${options['rotate']}"
    fi

    # Install the pdf to location expected for this specific rom
    echo "Linking $install_path to manual $postprocess_path"
    mkdir -p "$(dirname "$install_path")"
    ln -fsv "$postprocess_path" "$install_path"

    # Install a playlist symlink if applicable
    local playlist_name=$(get_playlist_name "$rom_name")
    if has_playlist_config "$rom_name" && [ ! "${installed_playlists["$playlist_name"]}" ]; then
      local playlist_install_path=$(render_template "$install_path_template" "${template_variables[@]}" name="$playlist_name")

      echo "Linking $playlist_install_path to manual $postprocess_path"
      ln -fsv "$postprocess_path" "$playlist_install_path"
      installed_playlists["$playlist_name"]=1
      installed_files["$playlist_install_path"]=1
    fi

    # Remove unused files (to avoid consuming too much disk space during the loop)
    if [ "$keep_downloads" != 'true' ]; then
      rm -v "$download_path"
    fi
  done < <(list_manuals)

  # Remove unused files
  # local base_path=$(render_template "$base_path_template" system="$system")
  # while read -r path; do
  #   [ "${installed_files["$path"]}" ] || rm -v "$path"
  # done < <(find "$base_path" -not -type d)
}

uninstall() {
  local base_path=$(render_template "$(setting '.manuals.paths.base')" system="$system")
  rm -rfv "$base_path"
}

"$1" "${@:3}"
