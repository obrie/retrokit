#!/usr/bin/env bash

rp_module_id="retrokit"
rp_module_desc="Configure Retrokit settings"
rp_module_section="config"
rp_module_flags="!all rpi"

function deps_retrokit() {
    aptInstall jq
}

function configure_retrokit() {
    # Copy menu icon
    local rpdir="$home/RetroPie/retropiemenu"
    cp -Rv "$md_data/icon.png" "$rpdir/icons/retrokit.png"

    local file='retrokit'
    local name='Retrokit'
    local desc='Manages your retrokit installation'
    local image="$home/RetroPie/retropiemenu/icons/retrokit.png"

    touch "$rpdir/$file.rp"

    # Add retrokit to the retropie system
    local function
    for function in $(compgen -A function _add_rom_); do
        "$function" "retropie" "RetroPie" "$file.rp" "$name" "$desc" "$image"
    done
}

function __get_settings_retrokit() {
    if [ -z "$__settings_retrokit" ]; then
        __settings_retrokit=$(_run_retrokit "$home/retrokit/bin/setup.sh" show_retrokit_settings about 2>/dev/null)
    fi

    echo "$__settings_retrokit"
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
            "vacuum" "Deletes media files no longer needed (scraped media, roms, etc.)."
        )

        local action=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
        if [[ -n "$action" ]]; then
            local text="Are you sure you want to \Zb$action\Zn $setupmodule?"
            text+="\n\n\ZbWARNING\Zn - This may overwrite existing configuration settings"
            dialog --colors --defaultno --yesno "$text" 22 76 2>&1 >/dev/tty || continue

            clear

            _run_retrokit "$home/retrokit/bin/setup.sh" "$action" "${@}"
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

            _run_retrokit "$home/retrokit/bin/update.sh" "$choice"
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

    _run_retrokit "$home/retrokit/bin/cache.sh" "${@}"
}

# Vacuum menu
function _gui_vacuum_retrokit() {
    while true; do
        local cmd=(dialog --colors --backtitle "$__backtitle" --cancel-label "Back" --menu "retrokit media management" 22 85 16)
        local options=(
            "all" "-> \Zbmanuals\Zn, \Zbmedia\Zn, \Zbroms\Zn"
            "manuals" "Deletes manuals for games no longer installed."
            "media" "Deletes scraped media for games no longer installed."
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

    output=$(_run_retrokit "$home/retrokit/bin/vacuum.sh" "${@}" 2>/dev/null)
    if [ -n "$output" ]; then
        dialog --colors --defaultno --no-collapse --yesno "$output" 22 85 2>&1 >/dev/tty || return

        # Run the commands
        echo "$output" | bash
    else
        printMsgs "dialog" "Nothing found to vacuum."
    fi

    clear
}

function _gui_edit_retrokit() {
    while true; do
        local cmd=(dialog --colors --backtitle "$__backtitle" --cancel-label "Back" --menu "Edit configurations" 22 85 16)
        local options=(
            0 ".env"
            1 "config/settings.json"
        )

        # Add system settings
        local index=2
        while read system; do
            options+=($index "config/systems/$system/settings.json")
            index=$((index+1))
        done < <(__get_settings_retrokit | jq -r '.systems[]' | sort)

        local choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
        if [[ -n "$choice" ]]; then
            local path_choice=${options[$((choice*2+1))]}

            # Build a template path for retrokit to find, so we can either use what's in
            # the configured profile or what's provided by retrokit
            local path_template
            if [[ "$path_choice" == ".env" ]]; then
                path_template="{app_dir}/$path_choice"
            else
                path_template=${path_choice/config\//\{config_dir\}\/}
            fi

            # Ask retrokit which path we should use as a starting point to edit
            local reference_path=$(_run_retrokit "$home/retrokit/bin/setup.sh" first_path about "$path_template" 2>/dev/null)

            # Use the default if the reference path is empty
            if [[ ! -s "$reference_path" ]]; then
                reference_path="$home/retrokit/$path_choice"
            fi

            # Identify where to save the file
            local profile_dir=$(_run_retrokit "$home/retrokit/bin/setup.sh" list_profile_dirs about 2>/dev/null | tail -n 1)

            # Create staging file
            local staging_path=$(mktemp)
            cp "$reference_path" "$staging_path"

            # Edit file
            if editFile "$staging_path" && ! diff "$staging_path" "$reference_path" >/dev/null; then
                local save_path="$profile_dir/$path_choice"
                mkdir -p "$(dirname "$save_path")"
                mv "$staging_path" "$save_path"

                # Make sure permissions are set correctly since we're running as root
                chown -R $user:$user "$profile_dir"
                chmod 664 "$save_path"

                printMsgs "dialog" "Saved to $save_path"
            fi
        else
            break
        fi
    done
}

function _run_and_show_retrokit() {
    output=$(_run_retrokit "${@}" 2>&1)

    printMsgs "dialog" "Command: ${*}\n\nOuput:\n\n$output"
}

function _run_retrokit() {
    sudo -u pi "${@}"
}
