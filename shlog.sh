# -*- mode: sh; eval: (sh-set-shell "bash") -*-

# Indices:    1        2     3       4    5     6
__LOG_NAMES=( critical error warning info debug trace )
__LOG_COLOR=( "31;1"   "91"  "33"    "32" "30"  "0"  )
__MUT_COLOR="37"
__LOG_SCOPES=()
__LOG_NONE=0

SHLOG_LEVEL=${SHLOG_LEVEL:-0} # 0 means turn off all.

function log {
    if [[ $1 -gt 0 || ${SHLOG_LEVEL} -gt 0 ]]; then
        local level=$1
        local level_min=1
        local level_max=${#__LOG_NAMES[@]}
        shift
        if [[ ${level} -ge ${level_min} && ${level} -le ${level_max} && ${level} -le ${SHLOG_LEVEL} ]]; then
            local name=${__LOG_NAMES[${level}]}
            local color=${__LOG_COLOR[${level}]}

            local tstamp="$(date -u +"%Y-%M-%dT%H:%m:%S.%sZ")"
            if [[ -n "${SHLOG_NOCOLOR}" ]]; then
                echo -n "${tstamp} "
            else
                echo -n "\033[${__MUT_COLOR}m${tstamp} "
            fi

            if [[ ${#__LOG_SCOPES[@]} -gt 0 ]]; then
                echo -n "${(j: >> :)__LOG_SCOPES} "
            fi

            if [[ -n "${SHLOG_NOCOLOR}" ]]; then
                echo "[${name}] $@"
            else
                echo "\033[${color}m[${name}] $@\033[0m"
            fi
        fi
    fi
}

function log_critical {
    log 1 $@
}

function log_error {
    log 2 $@
}

function log_warning {
    log 3 $@
}

function log_info {
    log 4 $@
}

function log_debug {
    log 5 $@
}

function log_trace {
    log 6 $@
}

function log_panic {
    local exit_code=$1
    shift
    msg_error $@
    exit ${exit_code}
}

function log_scope_enter {
    local scope=$1
    if [[ ! -z "${scope}" ]]; then
        log_trace "enter: ${scope}"
        __LOG_SCOPES=( ${__LOG_SCOPES[@]} "${scope}" )
    fi
}

function log_scope_exit {
    local scope=$1
    if [[ ! -z "${scope}" ]]; then
        log_trace "exit: ${scope}"
        local len=${#__LOG_SCOPES[@]}
        local new_len=$((len-1))
        __LOG_SCOPES=( ${__LOG_SCOPES[1,${new_len}]} )
    fi
}

function msg_success {
    log_info $@
    local color=${__LOG_COLOR[4]}
    echo "\033[${color}m✓\033[0m $@"
}

function msg_warning {
    log_warning $@
    local color=${__LOG_COLOR[3]}
    echo "\033[${color}m!\033[0m $@"
}

function msg_error {
    log_error $@
    local color=${__LOG_COLOR[2]}
    echo "\033[${color}m✗\033[0m $@"
}
