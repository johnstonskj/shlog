#!/usr/bin/env bash # -*- mode: sh; eval: (sh-set-shell "zsh") -*-

if ! type log_critical >/dev/null 2>&1; then
    SHLOG_SOURCE="${XDG_DATA_HOME:-$HOME/.local/share/shlog}/shlog.sh"
    if [[ -f ${SHLOG_SOURCE} ]]; then
        source ${SHLOG_SOURCE}
        log_debug "shlog loaded; SHLOG_LEVEL=${SHLOG_LEVEL}"
    else
        echo "Error: logging script ${SHLOG_SOURCE} not found."
    fi
fi

first() {
    log_scope_enter "first"
    log_info "calling second"
    second
    log_scope_exit "first"
}

second() {
    log_scope_enter "second.this"
    log_warning "doing something"
    log_scope_exit "second.that"
}

log_info "calling first"
first
log_info "all done"
