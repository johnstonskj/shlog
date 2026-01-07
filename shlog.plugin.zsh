# -*- mode: sh; eval: (sh-set-shell "zsh") -*-

##################################################################################################
#
# shlog.plugin.zsh -- Logging utility functions for shell scripts.
#
# Repository: https://github.com/johnstonskj/shlog
# Copyright: 2023 Simon Johnston <johnstonskj@gmail.com>
# License: http://www.apache.org/licenses/LICENSE-2.0
#
##################################################################################################

if [[ -n "${ZSH_VERSION}" ]]; then
    # See https://wiki.zshell.dev/community/zsh_plugin_standard#zero-handling
    # shellcheck disable=SC2277,2296,2299
    0="${ZERO:-${${0:#$ZSH_ARGZERO}:-${(%):-%N}}}"
    # shellcheck disable=SC2277,2296,2298
    0="${${(M)0:#/*}:-$PWD/$0}"
fi

# See https://wiki.zshell.dev/community/zsh_plugin_standard#standard-plugins-hash
declare -gA SHLOG
SHLOG[_PLUGIN_DIR]="${0:h}"
SHLOG[_FUNCTIONS]=""

if [[ -z "${LOG_LEVEL_OFF}" ]]; then
    typeset -gr LOG_LEVEL_OFF=0
fi
if [[ -z "${LOG_LEVEL_CRITICAL}" ]]; then
    typeset -gr LOG_LEVEL_CRITICAL=1
fi
if [[ -z "${LOG_LEVEL_ERROR}" ]]; then
    typeset -gr LOG_LEVEL_ERROR=2
fi
if [[ -z "${LOG_LEVEL_WARNING}" ]]; then
    typeset -gr LOG_LEVEL_WARNING=3
fi
if [[ -z "${LOG_LEVEL_INFO}" ]]; then
    typeset -gr LOG_LEVEL_INFO=4
fi
if [[ -z "${LOG_LEVEL_DEBUG}" ]]; then
    typeset -gr LOG_LEVEL_DEBUG=5
fi
if [[ -z "${LOG_LEVEL_TRACE}" ]]; then
    typeset -gr LOG_LEVEL_TRACE=6
fi

if [[ -n "${BASH_VERSION}" ]]; then
    emulate() {
        : # no-op
    }
fi

function _shlog_remember_fn() {
    local fn_name="${1}"
    if [[ -z ${SHLOG[_FUNCTIONS]} ]]; then
        SHLOG[_FUNCTIONS]="${fn_name}"
    elif [[ ",${SHLOG[_FUNCTIONS]}," != *",${fn_name},"* ]]; then
        SHLOG[_FUNCTIONS]="${SHLOG[_FUNCTIONS]},${fn_name}"
    fi
}
_shlog_remember_fn _shlog_remember_fn

function _shlog_plugin_init {
    emulate -L zsh
    
    if [[ "${OSTYPE}" == darwin* ]]; then
        SHLOG[_DATE_CMD]="$(which gdate)"
    else
        SHLOG[_DATE_CMD]="$(which date)"
    fi

    # Level Indices:    1        2     3       4    5     6
    SHLOG[_NAMES]="off  critical error warning info debug trace"
    SHLOG[_COLORS]="0   31;1     91    33      32   30    0;2"
    SHLOG[_ICONS]="⏹️   🧨       🔥    🛑      💬   🐞    🔬"
    SHLOG[_LEVEL_COUNT]=6

    SHLOG[_SCOPES]=""

    # These are client assignable, they need to be stand-alone to allow for customization.
    SHLOG_NOCOLOR=${SHLOG_NOCOLOR:-0}                          # 0 means colorize.
    SHLOG_LEVEL=${SHLOG_LEVEL:-${LOG_LEVEL_OFF}}               
    SHLOG_FORMATTER=${SHLOG_FORMATTER:-log_formatter_default}  # message formatter.

    # See https://wiki.zshell.dev/community/zsh_plugin_standard#functions-directory
    if [[ -d "${SHLOG[_PLUGIN_DIR]}/functions" ]]; then
        SHLOG[_PLUGIN_FNS_DIR]="${SHLOG[_PLUGIN_DIR]}/functions"
        # shellcheck disable=SC1009,SC1073,SC2154
        if [[ $PMSPEC != *f* ]]; then
            fpath+=( "${SHLOG[_PLUGIN_FNS_DIR]}" )
        elif [[ ${zsh_loaded_plugins[-1]} != */shlog && -z ${fpath[(r)${SHLOG[_PLUGIN_FNS_DIR]}]} ]]; then
            fpath+=( "${SHLOG[_PLUGIN_FNS_DIR]}" )
        fi

        local fn
        for fn in ${SHLOG[_PLUGIN_FNS_DIR]}/*(.:t); do
            autoload -Uz ${fn}
            _shlog_remember_fn ${fn}
        done
    fi
}
_shlog_remember_fn _shlog_plugin_init

function shlog_plugin_unload {
    emulate -L zsh

    local IFS
    local functions
    IFS=',' read -r -A functions <<< "${SHLOG[_FUNCTIONS]}"

    local fn
    # shellcheck disable=SC2068
    for fn in ${functions[@]}; do
        whence -w "${fn}" &> /dev/null && unfunction "${fn}"
    done

    local aliases
    IFS=',' read -r -A aliases <<< "${SHLOG[_ALIASES]}"

    local alias
    # shellcheck disable=SC2068
    for alias in ${aliases[@]}; do
        unalias "${alias}"
    done
    
    unset SHLOG

    # shellcheck disable=SC2296
    fpath=("${(@)fpath:#${0:A:h}}")

    unfunction shlog_plugin_unload
}

############################################################################
# Initialize Plugin
############################################################################

_shlog_plugin_init
true