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

if [[ -z "${ZSH_VERSION}" ]]; then
    emulate() {
        : # no-op
    }
fi

function shlog_remember_fn() {
    local fn_name="${1}"
    if [[ -z ${SHLOG[_FUNCTIONS]} ]]; then
        SHLOG[_FUNCTIONS]="${fn_name}"
    elif [[ ",${SHLOG[_FUNCTIONS]}," != *",${fn_name},"* ]]; then
        SHLOG[_FUNCTIONS]="${SHLOG[_FUNCTIONS]},${fn_name}"
    fi
}
shlog_remember_fn shlog_remember_fn

function shlog {
    emulate -L zsh

    SHLOG[_PLUGIN_DIR]="${0:h}"
    SHLOG[_FUNCTIONS]=""
    
    if [[ "${OSTYPE}" == darwin* ]]; then
        SHLOG[_DATE_FN]='gdate'
    else
        SHLOG[_DATE_FN]='date'
    fi

    # Level Indices:    1        2     3       4    5     6
    SHLOG[_NAMES]="off  critical error warning info debug trace"
    SHLOG[_COLORS]="0   31;1     91    33      32   30    0;2"
    SHLOG[_ICONS]="⏹️   🧨       🔥    🛑      💬   🐞    🔬"
    SHLOG[_LEVEL_COUNT]=6

    SHLOG[_SCOPES]=""

    # These are client assignable, they need to be stand-alone to allow for customization.
    SHLOG_NOCOLOR=${SHLOG_NOCOLOR:-0}                          # 0 means colorize.
    SHLOG_LEVEL=${SHLOG_LEVEL:-0}                              # 0 means turn off all.
    SHLOG_FORMATTER=${SHLOG_FORMATTER:-log_formatter_default}  # message formatter.

    # See https://wiki.zshell.dev/community/zsh_plugin_standard#functions-directory
    # shellcheck disable=SC1009,SC1073,SC2154
    if [[ $PMSPEC != *f* ]]; then
        fpath+=( "${SHLOG[_PLUGIN_DIR]}/functions" )
    elif [[ ${zsh_loaded_plugins[-1]} != */kalc && -z ${fpath[(r)${0:h}/functions]} ]]; then
        fpath+=( "${SHLOG[_PLUGIN_DIR]}/functions" )
    fi
}
shlog_remember_fn shlog

function shlog_plugin_unload {
    emulate -L zsh

    local IFS
    local functions
    if [[ -n "${ZSH_VERSION}" ]]; then
        IFS=',' read -r -A functions <<< "${SHLOG[_FUNCTIONS]}"
    else
        IFS=',' read -r -a functions <<< "${SHLOG[_FUNCTIONS]}"
    fi

    local fn
    # shellcheck disable=SC2068
    for fn in ${functions[@]}; do
        whence -w "${fn}" &> /dev/null && unfunction "${fn}"
    done
    
    unset SHLOG

    # shellcheck disable=SC2296
    fpath=("${(@)fpath:#${0:A:h}}")

    unfunction "${0}"
}