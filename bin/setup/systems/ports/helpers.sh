##############
# Package info helpers
##############

packages_path="$(mktemp -p "$tmp_ephemeral_dir")"
echo '{}' > "$packages_path"
json_merge '{system_config_dir}/packages.json' "$packages_path" backup=false >/dev/null

# Looks up information in the packages.json settings
port_setting() {
  jq -r "$1 | values" "$packages_path"
}
