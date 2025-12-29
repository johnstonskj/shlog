# -*- mode: sh; eval: (sh-set-shell "zsh") -*-

##################################################################################################
# Private Functions
##################################################################################################

# 
# Usage: _match_scope_symbol `string`
#
# Output: the prefix of `string` that matches the scope name/symbol regex 
#    `[a-zA-Z][a-zA-Z0-9_-]+`.
#
_match_scope_symbol() {
    emulate -L zsh

    local MATCH
    local symbol_re='(^[a-zA-Z][a-zA-Z0-9_-]+)'
    if [[ $1 =~ $symbol_re ]]; then
        [[ -n "${BASH_VERSION}" ]] && MATCH=${BASH_REMATCH[0]}
        [[ -n "${KSH_VERSION}" ]]  && MATCH=${.sh.match[0]}
    else
        MATCH=''
    fi
    printf "${MATCH}"
}
shlog_remember_fn _match_scope_symbol

##################################################################################################
# Public Functions >> Color Management
##################################################################################################

# 
# Usage: `ansi_display_attrs n n*`
#
# Parameters: `n` is either an integer, `i`, or a string `i[;i]*`.
#
# Output: the complete ANSI SGR string to set the corresponding display attributes.
#
ansi_display_attrs() {
    emulate -L zsh

    if [[ "${SHLOG_NOCOLOR}" == "0" ]]; then
        local IFS=";"
        printf "\033[$*m"
    else
        printf ""
    fi
}
shlog_remember_fn ansi_display_attrs

#
# Usage: `mute_color`
#
# Output: the complete ANSI SGR string to mute (dim) the currently set display attributes.
#
mute_color() {
    emulate -L zsh
    ansi_display_attrs 2
}
shlog_remember_fn mute_color

#
# Usage: `reset_color`
#
# Output: the complete ANSI SGR string to reset the display attributes to their default.
#
reset_color() {
    emulate -L zsh
    ansi_display_attrs 0
}
shlog_remember_fn reset_color

##################################################################################################
# Public Functions >> Message Levels
##################################################################################################

#
# Usage: `message_level_color` `level`
#
# Parameters: `level` is the message level, integer 1..6.
#
# Output: the complete ANSI SGR string to color the message for the given level.
#
message_level_color() {
    emulate -L zsh

    local level=$1
    if [[ -n "${ZSH_VERSION}" ]]; then
        IFS=' ' read -A colors <<< "${SHLOG[_COLORS]}"
    else
        IFS=' ' read -r -a colors <<< "${SHLOG[_COLORS]}"
    fi
    ansi_display_attrs ${colors[@]:${level}:1}
}
shlog_remember_fn message_level_color

#
# Usage: `message_level_icon` `level`
#
# Parameters: `level` is the message level, integer 1..6.
#
# Output: the Unicode icon character, as a string, for the given level.
#
message_level_icon() {
    emulate -L zsh

    local level=$1
    if [[ -n "${ZSH_VERSION}" ]]; then
        IFS=' ' read -A icons <<< "${SHLOG[_ICONS]}"
    else
        IFS=' ' read -r -a icons <<< "${SHLOG[_ICONS]}"
    fi
    printf "${icons[@]:${level}:1}"
}
shlog_remember_fn message_level_icon

#
# Usage: `message_level_name` `level`
#
# Parameters: `level` is the message level, integer 1..6.
#
# Output: the string name of the given level.
#
message_level_name() {
    emulate -L zsh

    local level=$1
    if [[ -n "${ZSH_VERSION}" ]]; then
        IFS=' ' read -A names <<< "${SHLOG[_NAMES]}"
    else
        IFS=' ' read -r -a names <<< "${SHLOG[_NAMES]}"
    fi
    printf "${names[@]:${level}:1}"
}
shlog_remember_fn message_level_name

##################################################################################################
# Public Functions >> Log Formatters
##################################################################################################

log_formatter_default() {
    emulate -L zsh

    local timestamp="${1}"
    local scopes="${2}"
    local level="${3}"
    local level_name="${4}"
    local level_icon="${5}"
    local message="${6}"

    mute_color
    local date_time=$(gdate --date="@${timestamp}" -u +'%Y-%m-%dT%H:%M:%SZ')
    printf "${date_time} "
    if [[ -n "$scopes" ]]; then
        printf "$(_log_scopes_display) "
    fi
    reset_color

    message_level_color $level
    printf "[${level_name}] ${level_icon} ${message}\n"
    reset_color
}
shlog_remember_fn log_formatter_default

log_formatter_friendly() {
    emulate -L zsh

    local timestamp="${1}"
    local scopes="${2}"
    local level="${3}"
    local level_name="${4}"
    local level_icon="${5}"
    local message="${6}"

    local date_time=$(gdate --date="@${timestamp}" +'%A, %B %e at %r')

    message_level_color $level
    printf "On ${date_time}\n"
    if [[ -n "${scopes}" ]]; then
        printf "    In the scope ${scopes// / ❱ }\n"
    fi

    case $level in
        1) printf "    A critical error occurred:\n" ;;
        2) printf "    An error occurred:\n" ;;
        3) printf "    A warning was issued:\n" ;;
        4) printf "    We wanted you to know:\n" ;;
        5) printf "    To help with debugging:\n" ;;
        6) printf "    To help with tracing:\n" ;;
        7) printf "    Something with the level ${level}' occurred:\n" ;;
    esac
    printf "        ${message}\n"
    reset_color
}
shlog_remember_fn log_formatter_friendly

log_formatter_json() {
    emulate -L zsh

    local timestamp="${1}"
    local scopes="${2}"
    local level="${3}"
    local level_name="${4}"
    local level_icon="${5}"
    local message="${6}"

    local scope_stack
    if [[ -n "${ZSH_VERSION}" ]]; then
        IFS=' ' read -A scope_stack <<< "${scopes}"
    else
        IFS=' ' read -r -a scope_stack <<< "${scopes}"
    fi

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
                printf "\"${reverse_stack[@]:$x:1}\", "
            else
                printf "\"${reverse_stack[@]:$x:1}\" "
            fi
        done
        printf "], "
    fi
    printf "\"level\": ${level},  "
    printf "\"levelName\": \"${level_name}\", "
    printf "\"levelIcon\": \"${level_icon}\", "
    printf "\"message\": \"${message}\" }\n"
}
shlog_remember_fn log_formatter_json

##################################################################################################
# Public Functions >> Log Emitters
##################################################################################################

log() {
    emulate -L zsh

    local level=${1}; shift

    if [[ ${level} -ge 1 && ${level} -le ${SHLOG_LEVEL} ]]; then
        # if currently specified level is larger than the last level,
        # reset it to a valid value.
        if [[ ${level} -gt ${SHLOG[_LEVEL_COUNT]} ]]; then
            level=${SHLOG[_LEVEL_COUNT]}
        fi

        local level_name=$(message_level_name $level)

        local level_icon=$(message_level_icon $level)

        local formatter="${SHLOG_FORMATTER}"
        if ! declare -F $formatter >/dev/null; then
            formatter="log_formatter_default"
        fi

        $formatter \
            $(date +"%s") \
            "${SHLOG[_SCOPES]}" \
            "$level" \
            "$level_name" \
            "$level_icon" \
            "$*"
    fi
}
shlog_remember_fn log

log_critical() {
    emulate -L zsh
    log 1 $@
}
shlog_remember_fn log_critical

log_error() {
    emulate -L zsh
    log 2 $@
}
shlog_remember_fn log_error

log_warning() {
    emulate -L zsh
    log 3 $@
}
shlog_remember_fn log_warning

log_info() {
    emulate -L zsh
    log 4 $@
}
shlog_remember_fn log_info

log_debug() {
    emulate -L zsh
    log 5 $@
}
shlog_remember_fn log_debug

log_trace() {
    emulate -L zsh
    log 6 $@
}
shlog_remember_fn log_trace

log_panic() {
    emulate -L zsh

    local exit_code=$1; shift

    log_critical $@
    exit ${exit_code}
}
shlog_remember_fn log_panic

log_shlog_settings() {
    emulate -L zsh

    log_scope_enter shlog-settings
    log_debug "SHLOG_NOCOLOR: ${SHLOG_NOCOLOR}"
    log_debug "SHLOG_LEVEL: ${SHLOG_LEVEL}"
    log_debug "SHLOG_FORMATTER: ${SHLOG_FORMATTER}"
    log_scope_enter internal
    log_debug "SHLOG[_PLUGIN_DIR]: ${SHLOG[_PLUGIN_DIR]}"
    log_debug "SHLOG[_FUNCTIONS]: ${SHLOG[_FUNCTIONS]}"
    log_debug "SHLOG[_NAMES]: ${SHLOG[_NAMES]}"
    log_debug "SHLOG[_COLORS]: ${SHLOG[_COLORS]}"
    log_debug "SHLOG[_ICONS]: ${SHLOG[_ICONS]}"
    log_debug "SHLOG[_LEVEL_COUNT]: ${SHLOG[_LEVEL_COUNT]}"
    log_debug "SHLOG[_SCOPES]: ${SHLOG[_SCOPES]}"
    log_scope_exit internal
    log_scope_exit shlog-settings
}
shlog_remember_fn log_shlog_settings

##################################################################################################
# Public Functions >> Log Scopes
##################################################################################################

_log_scopes_display() {
    printf "${SHLOG[_SCOPES]// /::}"
}
shlog_remember_fn _log_scopes_display

_log_scopes_push() {
    local scope="${1}"
    if [[ -z "${SHLOG[_SCOPES]}" ]]; then
        SHLOG[_SCOPES]="${scope}"
    else
        SHLOG[_SCOPES]="${SHLOG[_SCOPES]} ${scope}"
    fi
}
shlog_remember_fn _log_scopes_push

_log_scopes_pop() {
    local scopes
    if [[ -n "${ZSH_VERSION}" ]]; then
        IFS=' ' read -A scopes <<< "${SHLOG[_SCOPES]}"
    else
        IFS=' ' read -r -a scopes <<< "${SHLOG[_SCOPES]}"
    fi
    local len=${#scopes[@]}
    local new_len=$((len - 1))
    scopes=( ${scopes[@]:0:${new_len}} )
    SHLOG[_SCOPES]="${scopes[*]}"
}
shlog_remember_fn _log_scopes_pop

log_scope_enter() {
    emulate -L zsh

    local symbol=$(_match_scope_symbol "${1}")
    if [[ ! -z "${symbol}" ]]; then
        _log_scopes_push "${symbol}"
        log_trace "entered: ${symbol}"
    fi
}
shlog_remember_fn log_scope_enter

log_scope_exit() {
    emulate -L zsh

    local symbol=$(_match_scope_symbol "${1}")
    local exit_status=${2:-0}
    if [[ ! -z "${symbol}" ]]; then
        local base_msg="exiting: ${symbol}"
        if [[ ${exit_status} -eq 0 ]]; then
            log_trace "${base_msg}"
        else
            log_trace "${base_msg} with status ${exit_status}"
        fi
        _log_scopes_pop
    fi
    return ${exit_status}
}
shlog_remember_fn log_scope_exit
