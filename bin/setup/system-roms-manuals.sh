#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

# Tracks the epoch when a domain was last downloaded from
declare -A domain_timestamps

# The minimum amount of seconds to require between when a previous download
# completes from a given domain and when a new one starts.
# 
# This does not apply to archive.org domains.
DOWNLOAD_INTERVAL=60

# Maps manual language codes to Tesseract language codes
declare -A TESSERACT_LANGUAGES=(
  [ar]=ara
  [cs]=ces
  [da]=dan
  [de]=deu
  [en-au]=eng
  [en-ca]=eng
  [en-gb]=eng
  [en]=eng
  [es]=spa
  [fi]=fin
  [fr]=fra
  [it]=ita
  [ja]=jpn
  [ko]=kor
  [nl]=nld
  [no]=nor
  [pl]=pol
  [pt]=por
  [ru]=rus
  [sv]=swe
  [zh]=chi_sim
)

# Common settings
base_path_template=$(setting '.manuals.paths.base')
download_path_template=$(setting '.manuals.paths.download')
archive_path_template=$(setting '.manuals.paths.archive')
postprocess_path_template=$(setting '.manuals.paths.postprocess')
install_path_template=$(setting '.manuals.paths.install')
archive_url_template=$(setting '.manuals.archive.url')

# Downloads the given URL, ensuring that a certain amount of time has passed
# between subsequent downloads to the domain
download_with_sleep() {
  local url=$1
  local domain=$(echo "$url" | cut -d '/' -f 3)
  local last_downloaded_at=${domain_timestamps["$domain"]}

  if [ -n "$last_downloaded_at" ]; then
    local current_epoch=$(date +%s)
    local sleep_time=$(($last_downloaded_at + $DOWNLOAD_INTERVAL - $current_epoch))

    # Only sleep if DOWNLOAD_INTERVAL seconds hasn't passed yet
    if [ $sleep_time -gt 0 ]; then
      sleep $sleep_time
    fi
  fi

  local download_status=0
  download "$url" "${@:2}" || download_status=$?

  # Track the last time this domain was downloaded from
  if [[ "$domain" != *archive.org* ]]; then
    domain_timestamps["$domain"]=$(date +%s)
  fi

  return $download_status
}

# Downloads the manual from the given URL
download_pdf() {
  local source_url=$1
  local download_path=$2
  local max_attempts=3
  if [ $# -gt 2 ]; then local "${@:3}"; fi

  if [ -z "$source_url" ]; then
    # Source doesn't exist
    return 1
  fi

  mkdir -p "$(dirname "$download_path")"

  if [[ "$source_url" == *the-eye* ]]; then
    # Ignore for now until the-eye is back online
    return 1
  fi

  if [[ "$source_url" != *archive.org* ]]; then
    # For non-archive.org manuals, we reduce retries in order to keep site
    # owners happy and not overwhelm their servers
    max_attempts=1
  fi

  download_with_sleep "$source_url" "$download_path" max_attempts=$max_attempts
}

# Checks that the given file path is a valid pdf
validate_pdf() {
  mutool info "$1" &> /dev/null
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

  # Identify the filetype we're combining
  local extension=${filtered_paths[0]##*.}
  extension=${extension,,} # lowercase

  if [ "$extension" == 'pdf' ]; then
    if [ ${#filtered_paths[@]} -gt 1 ]; then
      # Combine PDF files
      gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile="$target_path" "${filtered_paths[@]}"
    else
      # Copy the PDF directly
      cp "${filtered_paths[0]}" "$target_path"
    fi
  else
    # Assume we're combining images

    # Remove alpha channel from PNG images as img2pdf cannot handle them
    while read source_path; do
      mogrify -background white -alpha remove -alpha off "$source_path"
    done < <(printf -- '%s\n' "${filtered_paths[@]}" | grep -i .png)

    img2pdf -s 72dpi --output "$target_path" "${filtered_paths[@]}"
  fi
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
    unzip -q -j "$source_path" -d "$extract_path"
    combine_images_to_pdf "$target_path" "$extract_path" "$filter_csv"
    rm -rf "$extract_path"
  elif [[ "$extension" =~ ^(rar|cbr)$ ]]; then
    # Rar of images -- extract and concatenate into pdf
    rm -rf "$extract_path"
    unrar e -idq "$source_path" "$extract_path/"
    combine_images_to_pdf "$target_path" "$extract_path" "$filter_csv"
    rm -rf "$extract_path"
  elif [[ "$extension" =~ ^(png|jpe?g)$ ]]; then
    combine_images_to_pdf "$target_path" "$(dirname "$source_path")" "$(basename "$source_path")"
  elif [[ "$extension" =~ ^(docx?)$ ]]; then
    unoconv -f pdf -o "$target_path" "$source_path"
  elif [[ "$extension" =~ ^(pdf)$ ]]; then
    # No conversion necessary -- copy to the target
    cp "$source_path" "$target_path"
  else
    # Unknown extension -- fail
    return 1
  fi

  validate_pdf "$target_path"
}

# Executes the `gs` command with standard defaults built-in
gs_exec() {
  local common_args=(
    -sDEVICE=pdfwrite
    -dCompatibilityLevel=1.4
    -dNOPAUSE
    -dQUIET
    -dBATCH
    -dAutoRotatePages=/None
    -dOptimize=true
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

  gs "${common_args[@]}" "${@}"
}

clean_pdf() {
  local pdf_path=$1

  mutool clean -gggg -D "$pdf_path" "$pdf_path"
}

# Selects specific pages from the PDF to include
slice_pdf() {
  local pdf_path=$1
  local pages=$2

  mutool merge -o "$pdf_path" "$pdf_path" "$pages"
}

# Rotates the PDF the given number of degrees
rotate_pdf() {
  local pdf_path=$1
  local rotate=$2

  mutool draw -R "$rotate" -o "$pdf_path" "$pdf_path"
}

# Attempts to make the PDF searchable by running the Tesseract OCR processor
# against the PDF with the specific languages
ocr_pdf() {
  local pdf_path=$1
  local languages=$2

  local staging_path="$tmp_ephemeral_dir/postprocess-ocr.pdf"
  rm -f "$staging_path"

  # Translate manual language codes to Tesseract language names
  local ocr_languages=()
  while read language; do
    ocr_languages+=(${TESSERACT_LANGUAGES[$language]})
  done < <(echo "$languages" | tr ',' '\n')
  local ocr_languages_csv=$(IFS=+ ; echo "${ocr_languages[*]}")

  local ocr_exit_code=0
  ocrmypdf -q -l "$ocr_languages_csv" --output-type pdf --skip-text --optimize 0 "$pdf_path" "$staging_path" || ocr_exit_code=$?

  if [ -f "$staging_path" ]; then
    if [ $ocr_exit_code -ne 0 ]; then
      echo "[WARN] OCR exit code is non-zero but generated pdf, still using"
    fi

    mv "$staging_path" "$pdf_path"
  else
    return 1
  fi
}

compress_pdf() {
  local pdf_path=$1

  # Filesize settings
  local min_filesize_threshold=$(setting '.manuals.postprocess.compress.filesize.minimum_bytes_threshold')
  local min_reduction_percent_threshold=$(setting '.manuals.postprocess.compress.filesize.reduction_percent_threshold')

  # Check that the filesize meets the necessary minimum threshold to trigger
  # this process
  if [ $(stat -c%s "$pdf_path") -lt "$min_filesize_threshold" ]; then
    return
  fi

  # Downsampling settings
  local downsample_enabled=$(setting '.manuals.postprocess.compress.downsample.enabled')
  local downsample_width=$(setting '.manuals.postprocess.compress.downsample.width')
  local downsample_height=$(setting '.manuals.postprocess.compress.downsample.height')
  local downsample_default_resolution=$(setting '.manuals.postprocess.compress.downsample.default_resolution')
  local downsample_min_resolution=$(setting '.manuals.postprocess.compress.downsample.min_resolution')
  local downsample_threshold=$(setting '.manuals.postprocess.compress.downsample.threshold')

  # Color settings
  local convert_icc_color_profile=$(setting '.manuals.postprocess.compress.color.icc')

  # Quality settings
  local color_quality_factor=$(setting '.manuals.postprocess.compress.quality_factor.color')
  local mono_quality_factor=$(setting '.manuals.postprocess.compress.quality_factor.mono')

  # Encoding settings
  local encode_uncompressed_images=$(setting '.manuals.postprocess.compress.encode.uncompressed')
  local encode_jpeg2000_images=$(setting '.manuals.postprocess.compress.encode.jpeg2000')

  # PDF Info
  local images_info=$(pdfimages -list "$pdf_path" | tail -n +3 | grep -Ev 'stencil')
  local has_icc_encoding=$(echo "$images_info" | awk '{print ($9)}' | grep icc)

  # Postscripting
  local postscript="
    << /ColorACSImageDict << /QFactor $color_quality_factor /Blend 1 /ColorTransform 1 /HSamples [2 1 1 2] /VSamples [2 1 1 2] >> >> setdistillerparams
    << /GrayACSImageDict << /QFactor $mono_quality_factor /Blend 1 /ColorTransform 1 /HSamples [2 1 1 2] /VSamples [2 1 1 2] >> >> setdistillerparams
  "

  # Track whether to actually compress
  local should_compress=false
  local force_compress=false

  # Apply a resolution calculation based on downsample dimensions
  if [ "$downsample_enabled" == 'true' ] && [ -n "$downsample_width" ] && [ -n "$downsample_height" ]; then
    # Generate postscript for defining the resolution
    local downsample_ps_start=''
    local downsample_ps_end=''

    # Calculate per-page resolutions
    while read page; do
      local page_info=$(echo "$images_info" | grep -E "^ *$page ")
      local page_image_width=$(echo "$page_info" | awk '{print ($4)}' | sort -nr | head -n 1)
      local page_image_height=$(echo "$page_info" | awk '{print ($5)}' | sort -nr | head -n 1)

      if [ $page_image_width -gt $downsample_width ] || [ $page_image_height -gt $downsample_height ]; then
        # Calculate the resolution required to keep the image at or below the
        # downsample dimensions
        local current_x_ppi=$(echo "$page_info" | awk '{print ($13)}' | sort -nr | head -n 1)
        local current_y_ppi=$(echo "$page_info" | awk '{print ($14)}' | sort -nr | head -n 1)
        local new_x_ppi=$(bc -l <<< "x = (${downsample_width}.0 / ${page_image_width}.0 * $current_x_ppi + 1); scale = 0; x / 1")
        local new_y_ppi=$(bc -l <<< "x = (${downsample_height}.0 / ${page_image_height}.0 * $current_y_ppi + 1); scale = 0; x / 1")
        local page_resolution

        # Determine the maximum resolution calculated
        if [ $new_x_ppi -lt $new_y_ppi ]; then
          page_resolution=$new_x_ppi
        else
          page_resolution=$new_y_ppi
        fi

        # Only use the calculated resolution if it's above the minimum
        if [ $page_resolution -lt $downsample_min_resolution ]; then
          page_resolution=$downsample_min_resolution
        fi

        downsample_ps_start="$downsample_ps_start $page PageNum eq { << /ColorImageResolution $page_resolution /GrayImageResolution $page_resolution /MonoImageResolution $page_resolution >> setdistillerparams } {"
        downsample_ps_end="} ifelse $downsample_ps_end"

        # Mark this as compressable
        should_compress=true
      fi
    done < <(echo "$images_info" | awk '{print ($1)}' | uniq | grep -v '^$')

    # Add the postscript
    if [ -n "$downsample_ps_start" ]; then
      downsample_ps_end="<< /ColorImageResolution $downsample_default_resolution /GrayImageResolution $downsample_default_resolution /MonoImageResolution $downsample_default_resolution >> setdistillerparams $downsample_ps_end"
      postscript="$postscript
        globaldict /PageNum 1 put
        << /BeginPage {
          $downsample_ps_start
          $downsample_ps_end
        } bind >> setpagedevice
        << /EndPage {
          exch pop
          0 eq dup { globaldict /PageNum PageNum 1 add put } if
        } bind >> setpagedevice
      "
    fi
  fi

  local gs_args=()

  # Convert ICC color profile to RGB
  if [ "$convert_icc_color_profile" == 'true' ] && [ "$has_icc_encoding" == 'true' ]; then
    gs_args+=(
      -sProcessColorModel=DeviceRGB
      -sColorConversionStrategy=sRGB
      -sColorConversionStrategyForImages=sRGB
      -dConvertCMYKImagesToRGB=true
      -dConvertImagesToIndexed=true
    )

    should_compress=true
    force_compress=true
  fi

  # Check if there are any encodings to convert
  if [ "$encode_uncompressed_images" == 'true' ] || [ "$encode_jpeg2000_images" == 'true' ]; then
    # Build the list of encodings to convert
    local encodings=()
    if [ "$encode_uncompressed_images" == 'true' ]; then
      encodings+=(image)
    fi
    if [ "$encode_jpeg2000_images" == 'true' ]; then
      encodings+=(jpx jbig2)
    fi
    local encodings_filter=$(IFS='|' ; echo "${encodings[*]}")

    # Check if there are any images that match the encodings
    if echo "$images_info" | grep -Ev 'index' | awk '{print ($9)}' | grep -qE "$encodings_filter"; then
      should_compress=true
      force_compress=true
    fi
  fi

  # Run the compression
  if [ "$should_compress" == 'true' ]; then
    local staging_path="$tmp_ephemeral_dir/postprocess-compress.pdf"

    # Create postscript file
    local postscript_path="$tmp_ephemeral_dir/postprocess-compress.ps"
    echo "$postscript" > "$postscript_path"

    gs_exec "${gs_args[@]}" \
      -sOutputFile="$staging_path" \
      -dColorImageDownsampleThreshold=$downsample_threshold -dGrayImageDownsampleThreshold=$downsample_threshold -dMonoImageDownsampleThreshold=$downsample_threshold \
      -dColorImageDownsampleType=/Bicubic -dGrayImageDownsampleType=/Bicubic \
      -dDownsampleColorImages=$downsample_enabled -dDownsampleGrayImages=$downsample_enabled -dDownsampleMonoImages=$downsample_enabled \
      -dColorImageResolution=$downsample_default_resolution -dGrayImageResolution=$downsample_default_resolution -dMonoImageResolution=$downsample_default_resolution \
      "$postscript_path" \
      -f "$pdf_path"

    # Calculate how much we compressed
    local pdf_bytes_uncompressed=$(stat -c%s "$pdf_path")
    local pdf_bytes_compressed=$(stat -c%s "$staging_path")
    local pdf_bytes_compressed_percent=$(bc -l <<< "($pdf_bytes_uncompressed - $pdf_bytes_compressed) / $pdf_bytes_uncompressed" | awk '{printf "%f", $0}')

    # Only use the compressed file if it's actually smaller
    if [ "$force_compress" == 'true' ] || (( $(echo "$pdf_bytes_compressed_percent >= $min_reduction_percent_threshold" | bc -l) )); then
      echo "[COMPRESS] Compressed $pdf_bytes_uncompressed => $pdf_bytes_compressed ($pdf_bytes_compressed_percent)"
      mv "$staging_path" "$pdf_path"
    else
      rm "$staging_path"
    fi
  fi
}

# Runs any configured post-processing on the PDF, including:
# * Slice
# * Truncate
# * Rotate
# * OCR
# * Compress
postprocess_pdf() {
  local pdf_path=$1
  local target_path=$2
  local languages=$3
  local pages=$4
  local rotate=${5:-0}

  local clean_enabled=$(setting '.manuals.postprocess.clean.enabled // false')
  if [ "$clean_enabled" == 'true' ]; then
    clean_pdf "$pdf_path"
  fi

  # Slice
  if [ -n "$pages" ]; then
    slice_pdf "$pdf_path" "$pages"
  fi

  # Rotate
  if [ "$rotate" != '0' ]; then
    rotate_pdf "$pdf_path" "$rotate"
  fi

  # OCR
  local ocr_enabled=$(setting '.manuals.postprocess.ocr.enabled // false')
  local ocr_completed=false
  if [ "$ocr_enabled" == 'true' ] && ocr_pdf "$pdf_path" "$languages"; then
    ocr_completed=true
  fi

  # Compress
  local compress_enabled=$(setting '.manuals.postprocess.compress.enabled // false')
  if [ "$compress_enabled" == 'true' ]; then
    compress_pdf "$pdf_path" "$languages"
  fi

  # Re-attempt OCR in case it failed pre-compress
  if [ "$ocr_enabled" == 'true' ] && [ "$ocr_completed" == 'false' ]; then
    echo '[WARN] OCR failed on first attempt, trying again'

    if ! ocr_pdf "$pdf_path" "$languages"; then
      echo '[WARN] OCR failed (both attempts)'
    fi
  fi

  # Move to target
  if validate_pdf "$pdf_path"; then
    mv "$pdf_path" "$target_path"
  else
    rm "$pdf_path"
    return 1
  fi
}

# Builds an associative array representing the manual
build_manual() {
  # Look up the variable for us to populate
  local -n manual_ref=$1

  # Romkit info
  local rom_name=$2
  local parent_title=$3
  local manual_languages=$4
  local manual_url=$5
  local postprocess_options=$6

  # Defaults
  manual_ref=(
    [rom_name]="$rom_name"
    [parent_title]="$parent_title"
    [languages]="$manual_languages"
    [format]=
    [pages]=
    [rotate]=
    [filter]=
    [playlist_install_path]=
  )

  # Define the CSV post-processing options
  if [ -n "$postprocess_options" ]; then
    while IFS='=' read -r option value; do
      manual_ref["$option"]=$value
    done < <(echo "$postprocess_options" | tr ',' '\n')
  fi

  # Fix URL:
  # * Explicitly escape the character "#" since rom names can have that character
  manual_ref['url']=${manual_url//#/%23}

  # Define the souce manual's extension
  local manual_url_extension=${manual_ref['url']##*.}
  local extension=${manual_ref['format']:-$manual_url_extension}
  manual_ref['extension']=${extension,,} # lowercase

  # Define the base path for manuals
  local base_template_variables=(system="$system")
  manual_ref['base_path']=$(render_template "$base_path_template" "${base_template_variables[@]}")

  # Define manual-specific install info
  local template_variables=(
    "${base_template_variables[@]}"
    base="${manual_ref['base_path']}"
    parent_title="$parent_title"
    languages="$manual_languages"
    name="$rom_name"
    extension="${manual_ref['extension']}"
  )
  manual_ref['download_path']=$(render_template "$download_path_template" "${template_variables[@]}")
  manual_ref['archive_path']=$(render_template "$archive_path_template" "${template_variables[@]}")
  manual_ref['postprocess_path']=$(render_template "$postprocess_path_template" "${template_variables[@]}")
  manual_ref['install_path']=$(render_template "$install_path_template" "${template_variables[@]}")
  manual_ref['archive_url']=$(render_template "$archive_url_template" "${template_variables[@]}")

  # Define playlist info
  manual_ref['playlist_name']=$(get_playlist_name "$rom_name")
  if has_playlist_config "$rom_name"; then
    manual_ref['playlist_install_path']=$(render_template "$install_path_template" "${template_variables[@]}" name="${manual['playlist_name']}")
  fi
}

# Lists the manuals to install
list_manuals() {
  if [ "$MANUALKIT_ARCHIVE" == 'true' ]; then
    # We're generating the manualkit archive -- list all manuals for all languages
    cat "$system_config_dir/manuals.tsv" | sed -r 's/^([^\t]+)\t([^\t]+)(.+)$/\1\t\1\t\2\3/'
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

  local keep_downloads=$(setting '.manuals.keep_downloads')
  local archive_processed=$(setting '.manuals.archive.processed')

  declare -A installed_files
  declare -A installed_playlists
  while IFS=$'\t' read -ra manual_data; do
    declare -A manual
    build_manual manual "${manual_data[@]}"

    # Look up the manual properties
    local url=${manual['url']}
    local archive_url=${manual['archive_url']}
    local download_path=${manual['download_path']}
    local archive_path=${manual['archive_path']}
    local postprocess_path=${manual['postprocess_path']}
    local install_path=${manual['install_path']}
    local playlist_install_path=${manual['playlist_install_path']}
    local playlist_name=${manual['playlist_name']}

    # Download the file
    if [ ! -f "$download_path" ] && [ ! -f "$archive_path" ] && [ ! -f "$postprocess_path" ]; then
      if ! { download_pdf "$archive_url" "$archive_path" max_attempts=1 || download_pdf "$url" "$download_path"; }; then
        # We couldn't download from the archive or source -- nothing to do
        echo "[${manual['rom_name']}] Failed to download from $url (archive: $archive_url)"
        continue
      fi
    fi

    # Use the archive as our download source
    if [ -f "$archive_path" ]; then
      download_path=$archive_path
    fi

    # Post-process the pdf
    if [ ! -f "$postprocess_path" ]; then
      mkdir -p "$(dirname "$postprocess_path")"

      if [ -f "$archive_path" ] && [ "$archive_processed" == 'true' ]; then
        # Archive file has already been processed -- just do a straight copy
        cp "$archive_path" "$postprocess_path"
      else
        # Download file hasn't been processed -- do so now
        convert_to_pdf "$download_path" "$tmp_ephemeral_dir/rom.pdf" "${manual['filter']}"
        postprocess_pdf "$tmp_ephemeral_dir/rom.pdf" "$postprocess_path" "${manual['languages']}" "${manual['pages']}" "${manual['rotate']}"
      fi
    fi

    # Final check to make sure the PDF is valid before installing it
    validate_pdf "$postprocess_path"

    # Install the pdf to location expected for this specific rom
    mkdir -p "$(dirname "$install_path")"
    ln -fsv "$postprocess_path" "$install_path"

    # Install a playlist symlink if applicable
    if [ -n "$playlist_install_path" ] && [ ! "${installed_playlists[$playlist_name]}" ]; then
      ln -fsv "$postprocess_path" "$playlist_install_path"
      installed_playlists[$playlist_name]=1
      installed_files[$playlist_install_path]=1
    fi

    # Remove unused files (to avoid consuming too much disk space during the loop)
    if [ "$keep_downloads" != 'true' ]; then
      rm -fv "$download_path" "$archive_path"
    fi

    installed_files[$install_path]=1
  done < <(list_manuals)

  # Remove unused symlinks
  local base_path=$(render_template "$base_path_template" system="$system")
  while read -r path; do
    [ "${installed_files[$path]}" ] || rm -v "$path"
  done < <(find "$base_path" -maxdepth 1 -type l -not -xtype d)
}

# Outputs the commands required to remove files no longer required by the current
# list of roms installed
vacuum() {
  # Ensure the system has manuals
  if [ ! -f "$system_config_dir/manuals.tsv" ]; then
    return
  fi

  local keep_downloads=$(setting '.manuals.keep_downloads')

  # Build the list of files we should *not* delete
  declare -A files_to_keep
  while IFS=$'\t' read -ra manual_data; do
    declare -A manual
    build_manual manual "${manual_data[@]}"

    # Keep paths to ensure they don't get deleted
    files_to_keep[${manual['install_path']}]=1
    files_to_keep[${manual['postprocess_path']}]=1

    # Keep downloads (if configured to persist)
    if [ "$keep_downloads" == 'true' ]; then
      files_to_keep[${manual['download_path']}]=1
      files_to_keep[${manual['archive_path']}]=1
    fi
  done < <(list_manuals)

  # Echo the commands (it's up to the user to evaluate them)
  while read -r path; do
    [ "${files_to_keep[$path]}" ] || echo "rm -v $(printf '%q' "$path")"
  done < <(find "${manual['base_path']}" -not -type d)
}

uninstall() {
  local base_path=$(render_template "$(setting '.manuals.paths.base')" system="$system")
  rm -rfv "$base_path"
}

"$1" "${@:3}"
