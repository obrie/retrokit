##############
# Package info helpers
##############

packages_data_file=$(mktemp -p "$tmp_ephemeral_dir")
json_merge '{system_config_dir}/packages.json' "$packages_data_file" backup=false >/dev/null

# Looks up information in the packages.json settings
port_setting() {
  jq -r "$1 | values" "$packages_data_file"
}
