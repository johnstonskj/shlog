# -*- mode: sh; eval: (sh-set-shell "zsh") -*-
#
# @name: shlog
# @brief: Logging utility functions for shell scripts.
# @repository: https://github.com/johnstonskj/shlog
# @copyright: 2023 Simon Johnston <johnstonskj@gmail.com>
# @license: MIT AND Apache-2.0
#
# ### Public Variables
#
# * `SHLOG_NOCOLOR`: Colorize output; default is 0.
# * `SHLOG_LEVEL`: The log level filter; default is `LOG_LEVEL_OFF`.
# * `SHLOG_FORMATTER`: The event formatter function; default is `log_formatter_default`.
#

###################################################################################################
# Shell Checking
#

if [[ -n "${ZSH_VERSION}" ]]; then
    # See https://wiki.zshell.dev/community/zsh_plugin_standard#zero-handling
    # shellcheck disable=SC2277,2296,2299
    0="${ZERO:-${${0:#$ZSH_ARGZERO}:-${(%):-%N}}}"
    # shellcheck disable=SC2277,2296,2298
    0="${${(M)0:#/*}:-$PWD/$0}"
elif [[ -n "${BASH_VERSION}" ]]; then
    emulate() {
        : # no-op
    }
fi

###################################################################################################
# @section Constants
# @description Constants for log levels.
#

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

###################################################################################################
# @section Global Variables
# @description
#
# These are client assignable, they need to be stand-alone to allow for customization.
#

SHLOG_NOCOLOR=${SHLOG_NOCOLOR:-0}                          # 0 means colorize.
SHLOG_LEVEL=${SHLOG_LEVEL:-${LOG_LEVEL_OFF}}               # no logging by default.
SHLOG_FORMATTER=${SHLOG_FORMATTER:-log_formatter_default}  # message formatter.

###################################################################################################
#  Global State
#
# - `_COLORS`: the color set for each log level
# - `_ICONS`: the icon character for each log level
# - `_LEVEL_COUNT`: the number of log levels
# - `_NAMES` the display name for each log level
# - `_SCOPES`: the scope stack
#

typeset -gA SHLOG

if [[ "${OSTYPE}" == darwin* ]]; then
    SHLOG[_DATE_CMD]="$(which gdate)"
else
    SHLOG[_DATE_CMD]="$(which date)"
fi

############################################################################
# @section Lifecycle
# @description Plugin lifecycle functions.
#

#
# @description Initialize the logging library as a Zsh plugin.
#
# @noargs
#
function shlog_plugin_init {
    emulate -L zsh

    # Level Indices:    1        2     3       4    5     6
    SHLOG[_NAMES]="off  critical error warning info debug trace"
    SHLOG[_COLORS]="0   31;1     91    33      32   30    0;2"
    SHLOG[_ICONS]="⏹️   🧨       🔥    🛑      💬   🐞    🔬"
    SHLOG[_LEVEL_COUNT]=6

    SHLOG[_SCOPES]=""
}

# @internal
function shlog_plugin_unload {
    emulate -L zsh

    unset SHLOG
}

if [[ -n "${BASH_VERSION}" ]]; then
    shlog_plugin_init
fi
