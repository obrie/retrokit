#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/common.sh"

usage() {
  echo "usage:"
  echo " $0 build [/path/to/output_dir/]|build_intro [path/to/output.pdf]"
  exit 1
}

build() {
  local target_dir=${1:-"$docs_dir/build"}
  mkdir -pv "$target_dir"

  build_gamelist '["system", "name", "players", "genres"]' "$target_dir/gamelist-by_system.pdf"
  build_gamelist '["name", "system", "players", "genres"]' "$target_dir/gamelist-by_name.pdf"
  build_intro "$target_dir/intro.pdf"
}

build_intro() {
  local target_file=${1:-"$docs_dir/build/intro.pdf"}
  local template_file=$(first_path '{docs_dir}/intro.html.jinja')

  local doc_data_file=$(mktemp -p "$tmp_ephemeral_dir" --suffix=.json)
  echo '{}' > "$doc_data_file"

  local stylesheet_file=$(first_path '{docs_dir}/stylesheets/manual.css')
  __build_file "$template_file" "$target_file" "$doc_data_file" "$stylesheet_file"
}

build_gamelist() {
  local table_headers=$1
  local target_file=$2

  local doc_data_file=$(mktemp -p "$tmp_ephemeral_dir" --suffix=.json)
  echo '{}' > "$doc_data_file"

  # Add list of games that are installed on all the systems
  local gamelist_data_file=$(mktemp -p "$tmp_ephemeral_dir")
  local gamelist=''

  while read system; do
    local system_title=$(xmlstarlet select -t -m "/*/*[name='$system']" -v 'fullname' "$home/.emulationstation/es_systems.cfg")
    echo "Generating $system_title gamelist..."

    while IFS=» read name players genres; do
      if [[ "$name" == *'"'* ]]; then
        name=$(echo -n "$name" | jq -aRs .)
      fi

      # Limit how many genres are displayed
      if [[ "$genres" == *,* ]]; then
        genres=$(echo "$genres" | tr ',' '\n' | awk '{ print length, $0 }' | sort -n -s | cut -d' ' -f2- | tail -n 1)
      fi

      gamelist="$gamelist\n{\"system\": \"$system_title\", \"name\": \"$name\", \"players\": \"$players\", \"genres\": \"$genres\"},"
    done < <(xmlstarlet select -t -m '/*/*' -v 'name' -o » -v 'players' -o » -v 'genre' -n "$home/.emulationstation/gamelists/$system/gamelist.xml" | xmlstarlet unesc | grep -Ev ' - Disc.*' | sort | uniq)
  done < <(setting '.systems[]')

  if [ -n "$gamelist" ]; then
    gamelist=${gamelist::-1}
  fi
  echo -e "{\"gamelist\": [$gamelist], \"table\": {\"headers\": $table_headers}}" > "$gamelist_data_file"
  json_merge "$gamelist_data_file" "$doc_data_file" backup=false
  json_merge '{docs_dir}/gamelist.json' "$doc_data_file" backup=false

  # Render the documentation
  local template_file=$(first_path '{docs_dir}/gamelist.html.jinja')
  local stylesheet_file=$(first_path '{docs_dir}/stylesheets/gamelist.css')
  __build_file "$template_file" "$target_file" "$doc_data_file" "$stylesheet_file"
}

# Builds the given file
__build_file() {
  local template_file=$1
  local target_file=$2
  local json_metadata_file=$3
  local page_stylesheet_file=$4
  local common_stylesheet_file=$(first_path '{docs_dir}/stylesheets/common.css')

  # Add hrefs
  json_edit "$json_metadata_file" \
    ".hrefs.common_stylesheet" "file://$common_stylesheet_file" \
    ".hrefs.page_stylesheet" "file://$page_stylesheet_file" \
    ".hrefs.base" "file://$docs_dir/"

  # Jinja => Markdown
  local html_output_file=$(mktemp -p "$tmp_ephemeral_dir" --suffix .html)
  jinja2 "$template_file" "$json_metadata_file" > "$html_output_file"

  # HTML => PDF
  chromium --headless --disable-gpu --run-all-compositor-stages-before-draw --print-to-pdf-no-header --print-to-pdf="$target_file" "$html_output_file" 2>/dev/null
}

if [[ $# -lt 1 ]]; then
  usage
fi

"$@"
