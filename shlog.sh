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
SHLOG_FORMATTER=${SHLOG_FORMATTER:-default}

mute_color() {
    if [[ -z "${SHLOG_NOCOLOR}" ]]; then
        printf "\033[37m"
    fi
}

message_color() {
    local level=$1
    if [[ -z "${SHLOG_NOCOLOR}" ]]; then
        printf "\033[${__LOG_COLOR[@]:${level}:1}m"
    fi
}

normal_color() {
    if [[ -z "${SHLOG_NOCOLOR}" ]]; then
        printf "\033[0m"
    fi
}

match_scope_symbol() {
    local symbol_re='(^[a-zA-Z][a-zA-Z0-9_-]+)'
    if [[ $1 =~ $symbol_re ]]; then
        [[ -n "${BASH_VERSION}" ]] && MATCH=${BASH_REMATCH[0]}
        [[ -n "${KSH_VERSION}" ]]  && MATCH=${.sh.match[0]}
    else
        MATCH=''
    fi
}

log_formatter_default() {
    local timestamp=$1
    local scope_stack_name=$2[@]
    if [ -n "${ZSH_VERSION}" ]; then
        local -a scope_stack=(${(P)scope_stack_name[@]})
    else
        local -a scope_stack=("${!scope_stack_name}")
    fi
    local level=$3
    local level_names_name=$4[@]
    if [ -n "${ZSH_VERSION}" ]; then
        local -a level_names=(${(P)level_names_name[@]})
    else
        local -a level_names=("${!level_names_name}")
    fi
    local level_name=${level_names[@]:${level}:1}
    local message=$5
    local date_time=$(gdate --date="@${timestamp}" -u +'%Y-%m-%dT%H:%M:%SZ')

    mute_color
    printf "${date_time} "
    if [[ ${#scope_stack[@]} -gt 0 ]]; then
        printf "%s" ${scope_stack[*]/#//}
        printf " "
    fi
    message_color $level
    printf "[${level_name}] $5"
    normal_color
    echo
}

log_formatter_friendly() {
    local timestamp=$1
    local scope_stack_name=$2[@]
    if [ -n "${ZSH_VERSION}" ]; then
        local -a scope_stack=(${(P)scope_stack_name[@]})
    else
        local -a scope_stack=("${!scope_stack_name}")
    fi
    local level=$3
    local level_names_name=$4[@]
    if [ -n "${ZSH_VERSION}" ]; then
        local -a level_names=(${(P)level_names_name[@]})
    else
        local -a level_names=("${!level_names_name}")
    fi
    local level_name=${level_names[@]:${level}:1}
    local message=$5
    local date_time=$(gdate --date="@${timestamp}" +'%A, %B %e at %r')

    message_color $level
    echo "On ${date_time}"
    if [[ ${#scope_stack[@]} -gt 0 ]]; then
        printf "    In the scope "
        printf "%s" ${scope_stack[*]/#//}
        echo
    fi
    case $level in
        0) echo "    A critical error occurred!" ;;
        1) echo "    An error occurred:" ;;
        2) echo "    A warning was issued:" ;;
        3) echo "    We wanted you to know:" ;;
        4) echo "    To help with debugging:" ;;
        5) echo "    To help with tracing:" ;;
    esac
    echo "    $5"
    normal_color
}

log_formatter_json() {
    local timestamp=$1
    local scope_stack_name=$2[@]
    if [ -n "${ZSH_VERSION}" ]; then
        local -a scope_stack=(${(P)scope_stack_name[@]})
    else
        local -a scope_stack=("${!scope_stack_name}")
    fi
    local level=$3
    local level_names_name=$4[@]
    if [ -n "${ZSH_VERSION}" ]; then
        local -a level_names=(${(P)level_names_name[@]})
    else
        local -a level_names=("${!level_names_name}")
    fi
    local level_name=${level_names[@]:${level}:1}
    local message=$5

    printf "{ \"timestamp\": $timestamp, "
    if [[ ${#scope_stack[@]} -gt 0 ]]; then
        local -a reverse_stack=()
        for i in ${scope_stack[@]}; do
            reverse_stack=($i ${reverse_stack[@]})
        done
        local last=$((${#reverse_stack[@]}-1))
        printf "\"scopes\": [ "
        for x in $(seq 0 $last); do
            if [[ $x -lt $last ]]; then
                printf %s "\"${reverse_stack[@]:$x:1}\", "
            else
                printf %s "\"${reverse_stack[@]:$x:1}\" "
            fi
        done
        printf "], "
    fi
    printf "\"level\": $level, \"levelName\": $level_name, "
    printf "\"message\": \"$5\" }\n"
}


log() {
    if [[ $1 -gt 0 || ${SHLOG_LEVEL} -gt 0 ]]; then
        local level=$1
        local level=$((level-1))
        local level_min=1
        local level_max=${#__LOG_NAMES[@]}
        shift
        if [[ ${level} -ge ${level_min} && ${level} -le ${level_max} && ${level} -le ${SHLOG_LEVEL} ]]; then
            local formatter="log_formatter_${SHLOG_FORMATTER}"
            if type $formatter >/dev/null 2>&1; then
                $formatter $(date +"%s") __LOG_SCOPES $level __LOG_NAMES "$*"
            else
                log_formatter_default $(date +"%s") __LOG_SCOPES $level __LOG_NAMES "$*"
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
    match_scope_symbol $1
    if [[ ! -z "${MATCH}" ]]; then
        __LOG_SCOPES=( ${__LOG_SCOPES[@]} "${MATCH}" )
        log_trace "entered: ${MATCH}"
    fi
}

log_scope_exit() {
    match_scope_symbol $1
    local exit_status=${2:-0}
    if [[ ! -z "${MATCH}" ]]; then
        if [[ ${exit_status} -eq 0 ]]; then
            log_trace "exiting: ${MATCH}"
        else
            log_trace "exiting: ${MATCH} with status ${exit_status}"
        fi
        local len=${#__LOG_SCOPES[@]}
        local new_len=$((len-1))
        __LOG_SCOPES=( ${__LOG_SCOPES[@]:0:${new_len}} )
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
