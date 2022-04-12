#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/common.sh"

usage() {
  echo "usage:"
  echo " $0 <build>"
  exit 1
}

build() {
  mkdir -p "$docs_dir/build"

  build_gamelist '["system", "name", "players", "genres"]' "$docs_dir/build/gamelist-by_system.pdf"
  build_gamelist '["name", "system", "players", "genres"]' "$docs_dir/build/gamelist-by_name.pdf"
}

build_intro() {
  return
}

build_gamelist() {
  local table_headers=$1
  local target_path=$2

  local doc_data_path="$tmp_ephemeral_dir/doc-extra.json"
  echo '{}' > "$doc_data_path"

  # Add hrefs
  local stylesheet_href=$(first_path "{docs_dir}/stylesheets/manual.css")
  local base_href=$docs_dir
  json_edit "$doc_data_path" \
    ".hrefs.stylesheet" "file://$stylesheet_href" \
    ".hrefs.base" "file://$base_href/"

  # Add list of games that are installed on all the systems
  local gamelist_data_path="$tmp_ephemeral_dir/doc-gamelist.json"
  local gamelist=''

  while read system; do
    local system_title=$(xmlstarlet select -t -m "/*/*[name='$system']" -v 'fullname' "$HOME/.emulationstation/es_systems.cfg")
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
    done < <(xmlstarlet select -t -m '/*/*' -v 'name' -o » -v 'players' -o » -v 'genre' -n "$HOME/.emulationstation/gamelists/$system/gamelist.xml" | xmlstarlet unesc | grep -Ev ' - Disc.*' | sort | uniq)
  done < <(setting '.systems[]')

  if [ -n "$gamelist" ]; then
    gamelist=${gamelist::-1}
  fi
  echo -e "{\"gamelist\": [$gamelist], \"table\": {\"headers\": $table_headers}}" > "$gamelist_data_path"
  json_merge "$gamelist_data_path" "$doc_data_path" backup=false
  json_merge '{docs_dir}/gamelist.json' "$doc_data_path" backup=false

  # Render the documentation
  local template=$(first_path '{docs_dir}/gamelist.html.jinja')
  __build_file "$template" "$target_path" "$doc_data_path"
}

# Builds the given file
__build_file() {
  local source_path=$1
  local target_path=$2
  local json_metadata_path=$3
  local stylesheets_path=$(first_path '{docs_dir}/stylesheets/manual.css')

  # Jinja => Markdown
  jinja2 "$source_path" "$json_metadata_path" > "$tmp_ephemeral_dir/doc.html"

  # HTML => PDF
  chromium --headless --disable-gpu --run-all-compositor-stages-before-draw --print-to-pdf-no-header --print-to-pdf="$target_path" "$tmp_ephemeral_dir/doc.html" 2>/dev/null

  # cp "$tmp_ephemeral_dir/doc.html" /tmp/doc.html
  # google-chrome /tmp/doc.html &

  # evince "$app_dir/output.pdf" &
}

if [[ $# -lt 1 ]]; then
  usage
fi

"$@"
