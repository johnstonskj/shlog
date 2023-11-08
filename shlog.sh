# -*- mode: sh; eval: (sh-set-shell "zsh") -*-

############################################################################
#
# shlog.sh -- Logging utility functions for shell scripts.
#
# Repository: https://github.com/johnstonskj/shlog.git
# Copyright: 2023 Simon Johnston <johnstonskj@gmail.com>
# License: http://www.apache.org/licenses/LICENSE-2.0
#
############################################################################

# Indices:    1        2     3       4    5     6
__LOG_NAMES=( critical error warning info debug trace )
__LOG_COLOR=( "31;1"   "91"  "33"    "32" "30"  "0"  )
__MUT_COLOR="37"
__LOG_SCOPES=()
__LOG_NONE=0

SHLOG_LEVEL=${SHLOG_LEVEL:-0} # 0 means turn off all.

__join() {
    local separator=$1; shift
    local first=$1; shift

    printf "%s" "$first" "${@/#/$separator}"
}

log() {
    if [[ $1 -gt 0 || ${SHLOG_LEVEL} -gt 0 ]]; then
        local level=$1
        local level=$((level-1))
        local level_min=1
        local level_max=${#__LOG_NAMES[@]}
        shift
        if [[ ${level} -ge ${level_min} && ${level} -le ${level_max} && ${level} -le ${SHLOG_LEVEL} ]]; then
            local name=${__LOG_NAMES[@]:${level}:1}
            local color=${__LOG_COLOR[@]:${level}:1}

            local tstamp="$(date -u +"%Y-%M-%dT%H:%m:%S.%sZ")"
            if [[ -n "${SHLOG_NOCOLOR}" ]]; then
                echo -n "${tstamp} "
            else
                echo -e -n "\e[${__MUT_COLOR}m${tstamp} "
            fi

            if [[ ${#__LOG_SCOPES[@]} -gt 0 ]]; then
                __join " >> " ${__LOG_SCOPES[@]}
                echo -n " "
            fi

            if [[ -n "${SHLOG_NOCOLOR}" ]]; then
                echo "[${name}] $@"
            else
                echo -e "\e[${color}m[${name}] $@\e[0m"
            fi
        fi
    fi
}

log_critical() {
    log 1 $@
}

log_error() {
    log 2 $@
}

log_warning() {
    log 3 $@
}

log_info() {
    log 4 $@
}

log_debug() {
    log 5 $@
}

log_trace() {
    log 6 $@
}

log_panic() {
    local exit_code=$1
    shift
    msg_error $@
    exit ${exit_code}
}

log_scope_enter() {
    local scope=$1
    if [[ ! -z "${scope}" ]]; then
        __LOG_SCOPES=( ${__LOG_SCOPES[@]} "${scope}" )
        log_trace "entered: ${scope}"
    fi
}

log_scope_exit() {
    local scope=$1
    local exit_status=${2:-0}
    if [[ ! -z "${scope}" ]]; then
        if [[ ${exit_status} -eq 0 ]]; then
            log_trace "exiting: ${scope}"
        else
            log_trace "exiting: ${scope} with status ${exit_status}"
        fi
        local len=${#__LOG_SCOPES[@]}
        local new_len=$((len-1))
        __LOG_SCOPES=( ${__LOG_SCOPES[@]:1:${new_len}} )
    fi
    return ${exit_status}
}

msg_success() {
    log_info $@
    local color=${__LOG_COLOR[@]:3:1}
    echo -e "\e[${color}m✓\e[0m $@"
}

msg_warning() {
    log_warning $@
    local color=${__LOG_COLOR[@]:2:1}
    echo -e "\e[${color}m!\e[0m $@"
}

msg_error() {
    log_error $@
    local color=${__LOG_COLOR[@]:1:1}
    echo -e "\e[${color}m✗\e[0m $@"
}
