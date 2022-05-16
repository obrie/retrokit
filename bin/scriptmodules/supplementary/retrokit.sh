#!/usr/bin/env bash

rp_module_id="retrokit"
rp_module_desc="Configure Retrokit settings"
rp_module_repo="git https://github.com/obrie/retrokit.git main"
rp_module_section="exp"
rp_module_flags="!all rpi"

function deps_retrokit() {
    aptInstall jq
}

function sources_retrokit() {
    if [ -d "$home/retrokit" ]; then
        pushd "$home/retrokit" > /dev/null
        sudo -u $user git pull --ff-only
        popd > /dev/null
    else
        gitPullOrClone "$home/retrokit"
    fi
}

function install_bin_retrokit() {
    chown -R $user:$user "$home/retrokit"
}

function configure_retrokit() {
    [[ "$md_mode" == "remove" ]] && return

    # Copy menu icon
    local rpdir="$home/RetroPie/retropiemenu"
    cp -Rv "$md_data/icon.png" "$rpdir/icons/retrokit.png"
    chown $user:$user "$rpdir/icons/retrokit.png"

    local file="retrokit"
    local name="Retrokit"
    local desc="Manages your retrokit installation"
    local image="$home/RetroPie/retropiemenu/icons/retrokit.png"

    touch "$rpdir/$file.rp"
    chown $user:$user "$rpdir/$file.rp"

    # Add retrokit to the retropie system
    local function
    for function in $(compgen -A function _add_rom_); do
        "$function" "retropie" "RetroPie" "$file.rp" "$name" "$desc" "$image"
    done
}

function remove_retrokit() {
    rm -fv \
        "$home/RetroPie/retropiemenu/retrokit.rp" \
        "$home/RetroPie/retropiemenu/icons/retrokit.png"

    # Remove menu item
    if [ -f "$home/.emulationstation/gamelists/retropie/gamelist.xml" ]; then
        xmlstarlet ed --inplace -d '/gameList/game[name="Retrokit"]' "$home/.emulationstation/gamelists/retropie/gamelist.xml"
    fi
}

# Main menu
function gui_retrokit() {
    while true; do
        local cmd=(dialog --colors --backtitle "$__backtitle" --menu "Retrokit configuration" 22 85 16)
        local options=(
            "setup" "Runs a retrokit setup module."
            "update" "Manages system updates (Raspbian, RetroPie, or Retrokit)."
            "cache" "Manages data cached by retrokit."
            "vacuum" "Removes media no longer be needed (scraped media, roms, etc.)."
            "migrate" "Migrate rom filenames after a DAT update."
            "edit" "Edit .env and settings.json files."
        )
        local choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
        if [[ -n "$choice" ]]; then
            "_gui_${choice}_retrokit"
        else
            break
        fi
    done
}

# Setup menu
function _gui_setup_retrokit() {
    while true; do
        local cmd=(dialog --colors --backtitle "$__backtitle" --cancel-label "Back" --menu "Retrokit setup configuration" 22 85 16)
        local options=(
            0 "all"
            1 "system"
            2 "system-roms"
        )

        # Add specific modules
        local index=3
        while read setupmodule; do
            options+=($index "$setupmodule")
            index=$((index+1))
        done < <(__get_settings_retrokit | jq -r '.setup[]')

        local choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
        if [[ -n "$choice" ]]; then
            local setupmodule=${options[$((choice*2+1))]}

            if [ "$setupmodule" == 'system' ] || [[ "$setupmodule" == system-* ]]; then
                _gui_system_select_retrokit 'setup_action' "$setupmodule"
            else
                _gui_setup_action_retrokit "$setupmodule"
            fi
        else
            break
        fi
    done
}

# Select an enabled system and run the callback function
function _gui_system_select_retrokit() {
    local callback_func=$1

    while true; do
        local cmd=(dialog --colors --backtitle "$__backtitle" --cancel-label "Back" --menu "$setupmodule configuration" 22 85 16)
        local options=(
            0 "all"
        )

        # Add specific systems
        local index=1
        while read system; do
            options+=($index "$system")
            index=$((index+1))
        done < <(__get_settings_retrokit | jq -r '.systems[]' | sort)

        local choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
        if [[ -n "$choice" ]]; then
            local system=${options[$((choice*2+1))]}

            # Run the callback
            "_gui_${callback_func}_retrokit" "${@:2}" "$system"
        else
            break
        fi
    done
}

# Setup action selection
function _gui_setup_action_retrokit() {
    local setupmodule=$1
    local system=$2

    while true; do
        local cmd=(dialog --colors --backtitle "$__backtitle" --cancel-label "Back" --menu "$setupmodule setup configuration ($system)" 22 85 16)
        local options=(
            "install" "Shortcut for: \Zbdepends\Zn, \Zbbuild\Zn, \Zbconfigure\Zn."
            "depends" "Installs required external dependencies."
            "build" "Installs non-configuration (e.g. binary, script) files."
            "config" "Sets up configuration-related files."
            "update" "Forces re-installation."
            "restore" "Restores configuration files to their defaults."
            "remove" "Removes non-configuration files, including dependencies."
            "uninstall" "Shortcut for: \Zbrestore\Zn, \Zbremove\Zn."
            "reinstall" "Shortcut for: \Zbuninstall\Zn, \Zbinstall\Zn."
            "vacuum" "Deletes media files no longer needed (scraped media, roms, etc.)."
        )

        local action=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
        if [[ -n "$action" ]]; then
            local text="Are you sure you want to \Zb$action\Zn $setupmodule?"
            text+="\n\n\ZbWARNING\Zn - This may overwrite existing configuration settings"
            dialog --colors --defaultno --yesno "$text" 22 76 2>&1 >/dev/tty || continue

            clear

            _run_and_show_retrokit "$home/retrokit/bin/setup.sh" "$action" "${@}"
        else
            break
        fi
    done
}

# Update menu
function _gui_update_retrokit() {
    while true; do
        local cmd=(dialog --colors --backtitle "$__backtitle" --cancel-label "Back" --menu "System update management" 22 85 16)
        local options=(
            "system" "Updates the current OS."
            "retropie" "-> \Zbretropie_setup\Zn, \Zbretropie_packages\Zn, \Zbemulator_configs\Zn"
            "retropie_setup" "Updates the Retropie-Setup repository."
            "retropie_packages" "Updates packages installed by RetroPie-Setup."
            "retrokit" "-> \Zbretrokit_setup\Zn, \Zbretrokit_profiles\Zn"
            "retrokit_setup" "Updates the retrokit repository."
            "retrokit_profiles" "Updates all git-managed retrokit profiles."
            "emulator_configs" "Re-configures and re-applies overrides for all emulators."
        )

        local choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
        if [[ -n "$choice" ]]; then
            local text="Are you sure you want to update $choice?"
            text+="\n\n\ZbWARNING\Zn - This may overwrite existing configuration settings"
            dialog --colors --defaultno --yesno "$text" 22 76 2>&1 >/dev/tty || continue

            clear

            _run_and_show_retrokit "$home/retrokit/bin/update.sh" "$choice"
        else
            break
        fi
    done
}

# Cache menu
function _gui_cache_retrokit() {
    while true; do
        local cmd=(dialog --colors --backtitle "$__backtitle" --cancel-label "Back" --menu "retrokit cache management" 22 85 16)
        local options=(
            "delete" "Deletes files cached from internal / external sources."
        )

        local action=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
        if [[ -n "$action" ]]; then
            _gui_system_select_retrokit 'cache_run' "$action"
        else
            break
        fi
    done
}

# Confirms and runs cache.sh actions
function _gui_cache_run_retrokit() {
    local action=$1
    local system=$2

    local text="Are you sure you want to \Zb$action\Zn the cache for \Zb$system\Zn?"
    dialog --colors --defaultno --yesno "$text" 22 76 2>&1 >/dev/tty || return

    clear

    _run_and_show_retrokit "$home/retrokit/bin/cache.sh" "${@}"
}

# Vacuum menu
function _gui_vacuum_retrokit() {
    while true; do
        local cmd=(dialog --colors --backtitle "$__backtitle" --cancel-label "Back" --menu "retrokit media management" 22 85 16)
        local options=(
            "all" "-> \Zbmanuals\Zn, \Zbmedia_cache\Zn, \Zbmedia\Zn, \Zbroms\Zn"
            "manuals" "Deletes manuals for games no longer installed."
            "media_cache" "Deletes cached scraper media for games no longer installed."
            "media" "Deletes non-cached media for games no longer installed."
            "roms" "Deletes rom files for games no longer installed."
        )

        local media_type=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
        if [[ -n "$media_type" ]]; then
            _gui_system_select_retrokit 'vacuum_run' "$media_type"
        else
            break
        fi
    done
}

# Confirms and runs vacuum.sh actions
function _gui_vacuum_run_retrokit() {
    local media_type=$1
    local system=$2

    local text="Are you sure you want to vacuum \Zb$media_type\Zn for \Zb$system\Zn?"
    text+="\n\n\ZbNOTE\Zn - An additional confirmation dialog will be shown before deleting any data."
    dialog --colors --defaultno --yesno "$text" 22 76 2>&1 >/dev/tty || return

    clear

    echo "Vacuuming $media_type in $system..."

    output=$(_run_retrokit "$home/retrokit/bin/vacuum.sh" "${@}" 2>/dev/null | tee /dev/tty)
    if [ -n "$output" ]; then
        dialog --colors --defaultno --no-collapse --yesno "$output" 22 85 2>&1 >/dev/tty || return

        # Run the commands
        local vacuum_output=$(echo "$output" | bash 2>&1)
        _show_msg_retrokit "Ouput:\n\n$vacuum_output"
    else
        _show_msg_retrokit "Nothing found to vacuum."
    fi

    clear
}

# Migrate menu
function _gui_migrate_retrokit() {
    _gui_system_select_retrokit 'migrate_run'
}

# Confirms and runs migrate.sh
function _gui_migrate_run_retrokit() {
    local system=$1

    local text="Are you sure you want to migrate \Zb$system\Zn?"
    text+="\n\n\ZbNOTE\Zn - An additional confirmation dialog will be shown before renaming any files."
    dialog --colors --defaultno --yesno "$text" 22 76 2>&1 >/dev/tty || return

    clear

    echo "Migrating $system..."

    output=$(_run_retrokit "$home/retrokit/bin/migrate.sh" "${@}" 2>/dev/null | tee /dev/tty)
    if [ -n "$output" ]; then
        dialog --colors --defaultno --no-collapse --yesno "$output" 22 85 2>&1 >/dev/tty || return

        # Run the commands
        local migrate_output=$(echo "$output" | bash 2>&1)
        _show_msg_retrokit "Ouput:\n\n$migrate_output"
    else
        _show_msg_retrokit "Nothing found to migrate."
    fi

    clear
}

# Edit menu
function _gui_edit_retrokit() {
    while true; do
        local cmd=(dialog --colors --backtitle "$__backtitle" --cancel-label "Back" --menu "Edit profiles" 22 85 16)
        local options=(
            0 "default"
        )

        # Add system settings
        local index=1
        while read profile; do
            options+=($index "$profile")
            index=$((index+1))
        done < <(_run_retrokit "$home/retrokit/bin/setup.sh" list_profiles about 2>/dev/null)

        local choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
        if [[ -n "$choice" ]]; then
            local profile_choice=${options[$((choice*2+1))]}
            _gui_edit_file_retrokit "$profile_choice"
        else
            break
        fi
    done
}

# Edit file selection
function _gui_edit_file_retrokit() {
    local profile=$1

    while true; do
        local cmd=(dialog --colors --backtitle "$__backtitle" --cancel-label "Back" --menu "Edit $profile configurations" 22 85 16)
        local options=(
            0 ".env"
            1 "config/settings.json"
            2 "config/systems/settings-common.json"
        )

        # Add system settings
        local index=3
        while read system; do
            options+=($index "config/systems/$system/settings.json")
            index=$((index+1))
        done < <(__get_settings_retrokit | jq -r '.systems[]' | sort)

        local choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
        if [[ -n "$choice" ]]; then
            local path_choice=${options[$((choice*2+1))]}

            # Determine which path we should use as a starting point to edit
            local reference_path="$home/retrokit/$path_choice"
            if [ "$profile" == 'default' ]; then
                save_path=$reference_path
            else
                save_path="$home/retrokit/profiles/$profile/$path_choice"

                while read active_profile; do
                    # If this profile has an override for the selected path, then we use that as the
                    # reference
                    local active_profile_path="$home/retrokit/profiles/$active_profile/$path_choice"
                    if [[ -f "$active_profile_path" ]]; then
                        reference_path=$active_profile_path
                    fi

                    # Stop when we've reached the currently selected profile as we don't want to use
                    # higher-priority profiles as the starting point
                    if [[ "$active_profile" == "$profile" ]]; then
                        break
                    fi
                done < <(_run_retrokit "$home/retrokit/bin/setup.sh" list_profiles about 2>/dev/null)
            fi

            # Create staging file
            local staging_path=$(mktemp)
            cp "$reference_path" "$staging_path"

            # Edit file
            if editFile "$staging_path" && ! diff "$staging_path" "$reference_path" >/dev/null; then
                sudo -u $user mkdir -p "$(dirname "$save_path")"
                mv "$staging_path" "$save_path"

                # Make sure permissions are set correctly since we're running as root
                chown -R $user:$user "$save_path"
                chmod 664 "$save_path"

                _show_msg_retrokit "Saved to $save_path"
            fi
        else
            break
        fi
    done
}

function _run_and_show_retrokit() {
    output=$(_run_retrokit "${@}" 2>&1 | tee /dev/tty)
    _show_msg_retrokit "Command: ${*}\n\nOuput:\n\n$output"
}

function _show_msg_retrokit() {
    dialog --backtitle "$__backtitle" --cr-wrap --no-collapse --msgbox "$1" 20 120 >/dev/tty
}

function _run_retrokit() {
    sudo -u pi "${@}"
}

function __get_settings_retrokit() {
    if [ -z "$__settings_retrokit" ]; then
        __settings_retrokit=$(_run_retrokit "$home/retrokit/bin/setup.sh" show_retrokit_settings about 2>/dev/null)
    fi

    echo "$__settings_retrokit"
}
