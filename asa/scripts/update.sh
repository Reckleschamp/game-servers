#!/usr/bin/env bash

install_or_update_server() {
    require_executable "${STEAMCMD}"

    if [[ ! -f "${ASA_EXE}" ]]; then
        log "ASA is not installed."
        log "Installing Steam application ${ASA_APP_ID} into ${ASA_DIR}."

        if ! run_steamcmd_with_retry \
            +@sSteamCmdForcePlatformType windows \
            +force_install_dir "${ASA_DIR}" \
            +login anonymous \
            +app_info_update 1 \
            +app_update "${ASA_APP_ID}" validate \
            +quit; then
            fatal "SteamCMD failed to install ${ASA_APP_ID} after all retry and recovery attempts."
        fi

    elif is_true "${UPDATE_SERVER}"; then
        log "Checking for ASA server updates."

        local update_args=(
            +@sSteamCmdForcePlatformType windows
            +force_install_dir "${ASA_DIR}"
            +login anonymous
            +app_info_update 1
            +app_update "${ASA_APP_ID}"
        )

        if is_true "${VALIDATE_SERVER}"; then
            log "Steam file validation is enabled."
            update_args+=(validate)
        fi

        update_args+=(+quit)

        if ! run_steamcmd_with_retry "${update_args[@]}"; then
            fatal "SteamCMD failed to update ${ASA_APP_ID} after all retry and recovery attempts."
        fi

    else
        log "Automatic ASA updates are disabled."
    fi

    if [[ ! -f "${ASA_EXE}" ]]; then
        fatal "SteamCMD completed, but ${ASA_EXE} was not found."
    fi
}

run_steamcmd_with_retry() {
    local max_attempts=2
    local attempt=1
    local delay=5
    local acf_path="${ASA_DIR}/steamapps/appmanifest_${ASA_APP_ID}.acf"
    local out_log
    local rc

    out_log="$(mktemp)"

    while (( attempt <= max_attempts )); do
        log "SteamCMD attempt ${attempt}/${max_attempts}."

        # Clear output from the previous attempt.
        : > "${out_log}"

        # Protect the pipeline from set -e / pipefail while preserving
        # SteamCMD's actual exit status instead of tee's exit status.
        if "${STEAMCMD}" "$@" 2>&1 | tee "${out_log}"; then
            rc=${PIPESTATUS[0]}
        else
            rc=${PIPESTATUS[0]}
        fi

        if steamcmd_result_ok "${rc}" "${out_log}"; then
            log "SteamCMD update succeeded."
            rm -f "${out_log}"
            return 0
        fi

        log "SteamCMD attempt ${attempt} failed (rc=${rc})."

        (( attempt++ ))

        if (( attempt <= max_attempts )); then
            log "Retrying in ${delay}s."
            sleep "${delay}"
        fi
    done

    log "All normal SteamCMD attempts failed."

    # Preserve the manifest during normal retries.
    # Only remove it after every normal attempt has failed.
    if [[ -f "${acf_path}" ]]; then
        log "Removing stale Steam appmanifest: ${acf_path}"
        rm -f "${acf_path}"
    else
        log "Steam appmanifest was not present: ${acf_path}"
    fi

    log "Performing final recovery attempt with validation."

    : > "${out_log}"

    if "${STEAMCMD}" \
        +@sSteamCmdForcePlatformType windows \
        +force_install_dir "${ASA_DIR}" \
        +login anonymous \
        +app_info_update 1 \
        +app_update "${ASA_APP_ID}" validate \
        +quit 2>&1 | tee "${out_log}"; then
        rc=${PIPESTATUS[0]}
    else
        rc=${PIPESTATUS[0]}
    fi

    if ! steamcmd_result_ok "${rc}" "${out_log}"; then
        log "SteamCMD recovery attempt failed (rc=${rc})."
        rm -f "${out_log}"
        return 1
    fi

    if [[ ! -f "${ASA_EXE}" ]]; then
        log "SteamCMD recovery completed, but ${ASA_EXE} was not found."
        rm -f "${out_log}"
        return 1
    fi

    rm -f "${out_log}"

    log "SteamCMD recovery attempt completed successfully."
    return 0
}

steamcmd_result_ok() {
    local rc="$1"
    local out_log="$2"

    # A non-zero SteamCMD exit code is always a failure.
    if [[ ${rc} -ne 0 ]]; then
        return 1
    fi

    # SteamCMD can occasionally return zero while reporting a failed
    # update in its output, so also detect known failure messages.
    if grep -qiE \
        'Access Denied|update canceled|state (is )?0x6|No connection|FAILED|Error! App|Timeout' \
        "${out_log}"; then
        return 1
    fi

    return 0
}