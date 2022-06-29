#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

setup_module_id='system-roms-manuals'
setup_module_desc='Downloads PDF manuals for viewing through manualkit'

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

# Tracks the epoch when a domain was last downloaded from
declare -A domain_timestamps

# Common settings
base_path_template=$(setting '.manuals.paths.base')
download_path_template=$(setting '.manuals.paths.download')
archive_path_template=$(setting '.manuals.paths.archive')
postprocess_path_template=$(setting '.manuals.paths.postprocess')
install_path_template=$(setting '.manuals.paths.install')
archive_url_template=$(setting '.manuals.archive.url')
fallback_to_source=$(setting '.manuals.archive.fallback_to_source')

configure() {
  local keep_downloads=$(setting '.manuals.keep_downloads')
  local archive_processed=$(setting '.manuals.archive.processed')

  declare -A installed_files
  declare -A installed_playlists
  while IFS=» read -ra manual_data; do
    declare -A manual
    __build_manual manual "${manual_data[@]}"

    # Look up the manual properties
    local url=${manual['url']}
    local archive_url=${manual['archive_url']}
    local download_path=${manual['download_path']}
    local archive_path=${manual['archive_path']}
    local postprocess_path=${manual['postprocess_path']}
    local install_path=${manual['install_path']}
    local playlist_install_path=${manual['playlist_install_path']}
    local playlist_name=${manual['playlist_name']}

    # Track whether we had to download the file
    local downloaded=false

    # Download the file
    if [ ! -f "$download_path" ] && [ ! -f "$archive_path" ] && [ ! -f "$postprocess_path" ]; then
      if ! { __download_pdf "$archive_url" "$archive_path" max_attempts=1 || __download_pdf "$url" "$download_path"; }; then
        # We couldn't download from the archive or source -- nothing to do
        echo "[${manual['rom_name']}] Failed to download from $archive_url (source: $url)"
        continue
      else
        downloaded=true
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
        rm -f "$tmp_ephemeral_dir/rom.pdf"
        __convert_to_pdf "$download_path" "$tmp_ephemeral_dir/rom.pdf" "${manual['filter']}" "${manual['rewrite_exif']}"
        __postprocess_pdf "$tmp_ephemeral_dir/rom.pdf" "$postprocess_path" "${manual['languages']}" "${manual['pages']}" "${manual['rotate']}"
      fi
    fi

    # Remove unused files (to avoid consuming too much disk space during the loop).
    # We only do this when processing new files -- existing files need to be handled
    # through a vacuum.
    if [ "$downloaded" == 'true' ] && [ "$keep_downloads" != 'true' ]; then
      rm -fv "$download_path" "$archive_path"
    fi

    # Final check to make sure the PDF is valid before installing it
    __validate_pdf "$postprocess_path"

    if [ -z "$playlist_name" ]; then
      # Install the pdf to location expected for this specific rom
      mkdir -p "$(dirname "$install_path")"
      ln_if_different "$postprocess_path" "$install_path"
      installed_files[$install_path]=1
    elif [ ! "${installed_playlists[$playlist_name]}" ]; then
      # Install a playlist symlink
      mkdir -p "$(dirname "$playlist_install_path")"
      ln_if_different "$postprocess_path" "$playlist_install_path"
      installed_files[$playlist_install_path]=1
      installed_playlists[$playlist_name]=1
    fi
  done < <(__list_manuals)

  # Remove unused symlinks
  local base_path=$(render_template "$base_path_template" system="$system")
  if [ -d "$base_path" ]; then
    while read -r path; do
      [ "${installed_files[$path]}" ] || rm -v "$path"
    done < <(find "$base_path" -maxdepth 1 -type l -not -xtype d)
  fi
}

# Lists the manuals to install
__list_manuals() {
  if [ "$MANUALKIT_ARCHIVE" == 'true' ]; then
    # We're generating the manualkit archive -- list all manuals for all languages
    each_path '{system_config_dir}/manuals.tsv' cat '{}' | sed -r 's/^([^\t]+)\t([^\t]+)(.+)$/\1\t\1\t\t\1\t\2\3/' | tr $'\t' '»'
  else
    romkit_cache_list | jq -r 'select(.manual) | [.name, .parent .title // .title, .playlist .name, .manual .name, .manual .languages, .manual .url, .manual .options] | join("»")'
  fi
}

# Builds an associative array representing the manual
__build_manual() {
  # Look up the variable for us to populate
  local -n manual_ref=$1

  # Romkit info
  local rom_name=$2
  local parent_title=$3
  local playlist_name=$4
  local manual_name=$5
  local manual_languages=$6
  local manual_url=$7
  local postprocess_options=$8

  # Defaults
  manual_ref=(
    [rom_name]="$rom_name"
    [parent_title]="$parent_title"
    [playlist_name]="$playlist_name"
    [name]="$manual_name"
    [languages]="$manual_languages"
    [format]=
    [pages]=
    [rotate]=
    [filter]=
    [rewrite_exif]=
    [playlist_install_path]=
  )

  # Define the CSV post-processing options
  if [ -n "$postprocess_options" ]; then
    while IFS='=' read -r option value; do
      manual_ref["$option"]=$value
    done < <(echo "$postprocess_options" | tr ';' '\n')
  fi

  # Add URL only if we're allowed to fall back to downloading from the original
  # source URL.
  # 
  # This also fixes:
  # * Explicitly escape the character "#" since rom names can have that character
  if [ "$fallback_to_source" != 'false' ]; then
    manual_ref['url']=${manual_url//#/%23}
  fi

  # Define the souce manual's extension
  local manual_url_extension=${manual_url##*.}
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
    name="$manual_name"
    languages="$manual_languages"
    rom_name="$rom_name"
    extension="${manual_ref['extension']}"
  )
  manual_ref['download_path']=$(render_template "$download_path_template" "${template_variables[@]}")
  manual_ref['archive_path']=$(render_template "$archive_path_template" "${template_variables[@]}")
  manual_ref['postprocess_path']=$(render_template "$postprocess_path_template" "${template_variables[@]}")
  manual_ref['install_path']=$(render_template "$install_path_template" "${template_variables[@]}")
  manual_ref['archive_url']=$(render_template "$archive_url_template" "${template_variables[@]}")
  manual_ref['archive_url']=${manual_ref['archive_url']//&/%26}

  # Define playlist info
  if [ -n "$playlist_name" ]; then
    manual_ref['playlist_install_path']=$(render_template "$install_path_template" "${template_variables[@]}" rom_name="${manual['playlist_name']}")
  fi
}

# Downloads the manual from the given URL
__download_pdf() {
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

  __download_with_sleep "$source_url" "$download_path" max_attempts=$max_attempts
}

# Downloads the given URL, ensuring that a certain amount of time has passed
# between subsequent downloads to the domain
__download_with_sleep() {
  local url=$1
  local domain=$(echo "$url" | cut -d '/' -f 3)
  domain=${domain:-localhost}
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

  # Track the last time this domain was downloaded from.  We can skip this for:
  # * archive.org
  # * localhost urls
  # * IP address urls
  # 
  # ...as everything else is likely from a website that throttles traffic
  if ! [[ "$domain" =~ (archive.org|localhost|[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+) ]]; then
    domain_timestamps["$domain"]=$(date +%s)
  fi

  return $download_status
}

# Converts a downloaded file to a PDF so that all manuals are in a standard
# format for us to work with
__convert_to_pdf() {
  local source_path=$1
  local target_path=$2
  local filter_csv=${3:-*}
  local rewrite_exif=${4:-false}

  mkdir -p "$(dirname "$target_path")"

  local extension=${source_path##*.}
  if [[ "$extension" =~ ^(zip|cbz|7z|cb7|rar|cbr)$ ]]; then
    # Source is an archive -- we need to extract, filter, and convert each matching file
    local extract_path="$tmp_ephemeral_dir/pdf-extract"
    rm -rf "$extract_path"

    # Extract contents
    if [[ "$extension" =~ ^(zip|cbz)$ ]]; then
      unzip -q -j "$source_path" -d "$extract_path"
    elif [[ "$extension" =~ ^(7z|cb7)$ ]]; then
      7z e -y -o"$extract_path/" "$source_path" >/dev/null
    else
      unrar -x --extract-no-paths "$source_path" "$extract_path/" >/dev/null
    fi

    # Filter files
    while read -r filter; do
      while read filtered_path; do
        if [ ! -f "$target_path" ]; then
          # Target doesn't exist yet -- let's initialize it with the first matched file
          __convert_file_to_pdf "$filtered_path" "$target_path"
        else
          # We have at least 2 files matched in the filter.  Now we need to merge.
          mv "$target_path" "$tmp_ephemeral_dir/merge-1.pdf"
          __convert_file_to_pdf "$filtered_path" "$tmp_ephemeral_dir/merge-2.pdf" rewrite_exif="$rewrite_exif"
          python3 "$bin_dir/tools/pdfmerge.py" "$target_path" "$tmp_ephemeral_dir/merge-1.pdf" "$tmp_ephemeral_dir/merge-2.pdf"
        fi
      done < <(find "$extract_path" -type f -wholename "$extract_path/$filter" | sort)
    done < <(echo "$filter_csv" | tr ',' '\n')

    rm -rf "$extract_path"
  else
    __convert_file_to_pdf "$source_path" "$target_path" rewrite_exif="$rewrite_exif"
  fi

  __validate_pdf "$target_path"
}

# Converts a downloaded file to a PDF so that all manuals are in a standard
# format for us to work with
__convert_file_to_pdf() {
  local source_path=$1
  local target_path=$2
  local rewrite_exif=false
  if [ $# -gt 2 ]; then local "${@:3}"; fi

  local extension=${source_path##*.}
  extension=${extension,,} # lowercase
  if [[ "$extension" =~ ^(html?|txt)$ ]]; then
    # Print to pdf via chrome
    # 
    # Chromium can't access files in hidden directories, so it needs to be sourced
    # from a different directory
    local chromium_path="$tmp_ephemeral_dir/$(basename "$source_path")"
    cp "$source_path" "$chromium_path"
    chromium --headless --disable-gpu --run-all-compositor-stages-before-draw --print-to-pdf-no-header --print-to-pdf="$target_path" "$chromium_path" 2>/dev/null
    rm "$chromium_path"
  elif [[ "$extension" =~ ^(png|jpe?g|bmp|gif|tif)$ ]]; then
    # Sometimes images have corrupt exif data that causes img2pdf to fail.  In those
    # cases where we know this is the case, we'll rewrite the exif data so that it
    # can be properly parsed.
    if [ "$rewrite_exif" == 'true' ]; then
      exiftool -q -all= -tagsfromfile @ -all:all "$source_path"
    fi

    img2pdf -s 72dpi --engine internal --output "$target_path" "$source_path"
  elif [[ "$extension" =~ ^(docx?|rtf|wri)$ ]]; then
    unoconv -f pdf -o "$target_path" "$source_path"
  elif [[ "$extension" =~ ^(pdf)$ ]]; then
    # No conversion necessary -- copy to the target
    cp "$source_path" "$target_path"
  else
    # Unknown extension -- fail
    return 1
  fi
}

# Runs any configured post-processing on the PDF, including:
# * Slice
# * Truncate
# * Rotate
# * OCR
# * Compress
__postprocess_pdf() {
  local pdf_path=$1
  local target_path=$2
  local languages=$3
  local pages=$4
  local rotate=${5:-0}

  local clean_enabled=$(setting '.manuals.postprocess.clean.enabled // false')
  if [ "$clean_enabled" == 'true' ]; then
    __clean_pdf "$pdf_path"
  fi

  local mutate_enabled=$(setting '.manuals.postprocess.mutate.enabled // false')
  if [ "$mutate_enabled" == 'true' ]; then
    # Slice
    if [ -n "$pages" ]; then
      __slice_pdf "$pdf_path" "$pages"
    fi

    # Rotate
    if [ "$rotate" != '0' ]; then
      __rotate_pdf "$pdf_path" "$rotate"
    fi
  fi

  # OCR
  local ocr_enabled=$(setting '.manuals.postprocess.ocr.enabled // false')
  local ocr_completed=false
  if [ "$ocr_enabled" == 'true' ] && __ocr_pdf "$pdf_path" "$languages"; then
    ocr_completed=true
  fi

  # Compress
  local compress_enabled=$(setting '.manuals.postprocess.compress.enabled // false')
  if [ "$compress_enabled" == 'true' ]; then
    __compress_pdf "$pdf_path" "$languages"
  fi

  # Re-attempt OCR in case it failed pre-compress
  if [ "$ocr_enabled" == 'true' ] && [ "$ocr_completed" == 'false' ]; then
    echo '[WARN] OCR failed on first attempt, trying again'

    if ! __ocr_pdf "$pdf_path" "$languages"; then
      echo '[WARN] OCR failed (both attempts)'
    fi
  fi

  # Move to target
  if __validate_pdf "$pdf_path"; then
    mv "$pdf_path" "$target_path"
  else
    rm "$pdf_path"
    return 1
  fi
}

# Cleans up the structure of the PDF and removes unnecessary data
__clean_pdf() {
  local pdf_path=$1

  mutool clean -gggg -D "$pdf_path" "$pdf_path"
}

# Selects specific pages from the PDF to include
__slice_pdf() {
  local pdf_path=$1
  local pages=$2

  mutool merge -o "$pdf_path" "$pdf_path" "$pages"
}

# Rotates the PDF the given number of degrees
__rotate_pdf() {
  local pdf_path=$1
  local rotate=$2

  mutool draw -R "$rotate" -o "$pdf_path" "$pdf_path"
}

# Attempts to make the PDF searchable by running the Tesseract OCR processor
# against the PDF with the specific languages
__ocr_pdf() {
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
  ocrmypdf -q -l "$ocr_languages_csv" --output-type pdf --skip-text --optimize 0 --tesseract-timeout 1200 --skip-big 250 "$pdf_path" "$staging_path" || ocr_exit_code=$?

  if [ -f "$staging_path" ]; then
    if [ $ocr_exit_code -ne 0 ]; then
      echo "[WARN] OCR exit code is non-zero but generated pdf, still using"
    fi

    mv "$staging_path" "$pdf_path"
  else
    return 1
  fi
}

# Attempts to compress the PDF to save disk space
__compress_pdf() {
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
  local downsample_max_resolution=$(setting '.manuals.postprocess.compress.downsample.max_resolution')
  local downsample_min_resolution=$(setting '.manuals.postprocess.compress.downsample.min_resolution')
  local downsample_threshold=$(setting '.manuals.postprocess.compress.downsample.threshold')

  # Color settings
  local convert_icc_color_profile=$(setting '.manuals.postprocess.compress.color.icc')

  # Quality settings
  local quality_factor_highres_color=$(setting '.manuals.postprocess.compress.quality_factor.highres_color')
  local quality_factor_highres_gray=$(setting '.manuals.postprocess.compress.quality_factor.highres_gray')
  local quality_factor_highres_threshold=$(setting '.manuals.postprocess.compress.quality_factor.highres_threshold')
  local quality_factor_lowres_color=$(setting '.manuals.postprocess.compress.quality_factor.lowres_color')
  local quality_factor_lowres_gray=$(setting '.manuals.postprocess.compress.quality_factor.lowres_gray')
  local pass_through_jpeg=$(setting '.manuals.postprocess.compress.quality_factor.pass_through_jpeg')
  local acs_image_dict_settings='/Blend 1 /ColorTransform 1 /HSamples [2 1 1 2] /VSamples [2 1 1 2]'

  # Encoding settings
  local encode_uncompressed_images=$(setting '.manuals.postprocess.compress.encode.uncompressed')
  local encode_jpeg2000_images=$(setting '.manuals.postprocess.compress.encode.jpeg2000')

  # PDF Info
  local images_info=$("$bin_dir/tools/pdfimages.py" "$pdf_path" 2>/dev/null)
  if [ $? -ne 0 ]; then
    exit 1
  fi
  local has_icc_encoding=$(echo "$images_info" | awk '{print ($9)}' | grep ICCBased)

  # Postscripting
  local postscript="<<
    /DownsampleColorImages $downsample_enabled
    /DownsampleGrayImages $downsample_enabled
    /DownsampleMonoImages $downsample_enabled
    /ColorImageResolution $downsample_max_resolution
    /GrayImageResolution $downsample_max_resolution
    /MonoImageResolution $downsample_max_resolution
    /ColorACSImageDict << /QFactor $quality_factor_highres_color $acs_image_dict_settings >>
    /GrayACSImageDict << /QFactor $quality_factor_highres_gray $acs_image_dict_settings >>
    /PassThroughJPEGImages $pass_through_jpeg
  >> setdistillerparams
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
      # Identify the size of the image we're working with.  We approximate size and resolution
      # by taking the largest of what we see.  It's not ideal, but it's close enough.  Ideally
      # we would change the resolution individually of each image on the page.
      local page_info=$(echo "$images_info" | grep -E "^$page")
      local page_image_width=$(echo "$page_info" | awk '{print ($18)}' | sort -nr | head -n 1)
      local page_image_height=$(echo "$page_info" | awk '{print ($19)}' | sort -nr | head -n 1)
      local page_distiller_params=''

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

        page_distiller_params="
          /DownsampleColorImages true
          /DownsampleGrayImages true
          /DownsampleMonoImages true
          /ColorImageResolution $page_resolution
          /GrayImageResolution $page_resolution
          /MonoImageResolution $page_resolution
        "

        # Mark this as compressable
        should_compress=true
      else
        page_distiller_params="
          /DownsampleColorImages false
          /DownsampleGrayImages false
          /DownsampleMonoImages false
        "
      fi

      # Enable pass-through JPEG on a per-page basis based on the target
      # image dimension thresholds
      if [ "$pass_through_jpeg" == 'false' ]; then
        local has_highres_width=$(bc -l <<< "(${page_image_width}.0 / ${downsample_width}.0) >= $quality_factor_highres_threshold")
        local has_highres_height=$(bc -l <<< "(${page_image_height}.0 / ${downsample_height}.0) >= $quality_factor_highres_threshold")

        if [ $has_highres_width -eq 0 ] && [ $has_highres_height -eq 0 ]; then
          # If there's a low-res factor, use that -- otherwise enable jpeg pass-through
          if [ -n "$quality_factor_lowres_color" ] && [ -n "$quality_factor_lowres_gray" ]; then
            page_distiller_params+="
              /PassThroughJPEGImages false
              /ColorACSImageDict << /QFactor $quality_factor_lowres_color $acs_image_dict_settings >>
              /GrayACSImageDict << /QFactor $quality_factor_lowres_gray $acs_image_dict_settings >>
            "
          else
            page_distiller_params+="
              /PassThroughJPEGImages true
            "
          fi
        else
          # Use high-res quality factor
          page_distiller_params+="
            /PassThroughJPEGImages false
            /ColorACSImageDict << /QFactor $quality_factor_highres_color $acs_image_dict_settings >>
            /GrayACSImageDict << /QFactor $quality_factor_highres_gray $acs_image_dict_settings >>
          "
        fi
      fi

      downsample_ps_start+=" $page PageNum eq { << $page_distiller_params >> setdistillerparams } {"
      downsample_ps_end="} ifelse $downsample_ps_end"
    done < <(echo "$images_info" | awk '{print ($1)}' | uniq | grep -v '^$')

    # Add the postscript
    if [ -n "$downsample_ps_start" ]; then
      postscript="
        globaldict /PageNum 1 put
        << /BeginPage {
          $downsample_ps_start
          $postscript
          $downsample_ps_end
        } bind >> setpagedevice
        << /EndPage {
          exch pop
          0 eq dup { globaldict /PageNum PageNum 1 add put } if
        } bind >> setpagedevice
      "
    fi
  fi

  # Try to compress since we're adjusting the quality factor of JPEGs
  if [ "$pass_through_jpeg" == 'false' ]; then
    should_compress=true
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
      encodings+=(FlateDecode)
    fi
    if [ "$encode_jpeg2000_images" == 'true' ]; then
      encodings+=(JPXDecode JBIG2Decode)
    fi
    local encodings_filter=$(IFS='|' ; echo "${encodings[*]}")

    # Check if there are any images that match the encodings
    if echo "$images_info" | awk '{print ($9)}' | grep -qE "$encodings_filter"; then
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

    if __gs_exec "${gs_args[@]}" \
        -sOutputFile="$staging_path" \
        -dColorImageDownsampleThreshold=$downsample_threshold -dGrayImageDownsampleThreshold=$downsample_threshold -dMonoImageDownsampleThreshold=$downsample_threshold \
        -dColorImageDownsampleType=/Bicubic -dGrayImageDownsampleType=/Bicubic \
        -dPDFSTOPONERROR \
        "$postscript_path" \
        -f "$pdf_path"; then
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
    else
      echo '[WARN] Failed to run ghostscript compression'
      rm "$staging_path"
    fi
  fi
}

# Executes the `gs` command with standard defaults built-in
__gs_exec() {
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

# Checks that the given file path is a valid pdf
__validate_pdf() {
  mutool info "$1" &> /dev/null
}

# Outputs the commands required to remove files no longer required by the current
# list of roms installed
vacuum() {
  local keep_downloads=$(setting '.manuals.keep_downloads')
  local base_path=$(render_template "$base_path_template" system="$system")
  if [ ! -d "$base_path" ]; then
    # No manuals configured
    return
  fi

  # Build the list of files we should *not* delete
  declare -A files_to_keep
  while IFS=» read -ra manual_data; do
    declare -A manual
    __build_manual manual "${manual_data[@]}"

    # Keep paths to ensure they don't get deleted
    files_to_keep[${manual['install_path']}]=1
    files_to_keep[${manual['postprocess_path']}]=1

    local playlist_name=${manual['playlist_name']}
    if [ -n "$playlist_name" ]; then
      files_to_keep[${manual['playlist_install_path']}]=1
    fi

    # Keep downloads (if configured to persist)
    if [ "$keep_downloads" == 'true' ]; then
      files_to_keep[${manual['download_path']}]=1
      files_to_keep[${manual['archive_path']}]=1
    fi
  done < <(__list_manuals)

  # Echo the commands (it's up to the user to evaluate them)
  while read -r path; do
    [ "${files_to_keep[$path]}" ] || echo "rm -fv $(printf '%q' "$path")"
  done < <(find "$base_path" -not -type d)
}

setup "$1" "${@:3}"
