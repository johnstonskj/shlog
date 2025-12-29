# -*- mode: sh; eval: (sh-set-shell "bash") -*-

if [[ -n "${ZSH_VERSION}" ]]; then
    source "./shlog.plugin.zsh"
else
    source "shlog.sh"
fi

assert_eq() {
    if [[ -n "${ZSH_VERSION}" ]]; then
        local test_name=${funcstack[2]}
    else
        local test_name=${FUNCNAME[1]}
    fi
    local actual="${1%$\'\n\'}"
    local expected="${2}"

    if [[ ! "${actual}" == "${expected}" ]]; then
        echo "Test case '${test_name}' failed; ! (lhs == rhs)"
        diff --color=always <(echo "${actual}") <(echo "${expected}")
        return 1
    else
        return 0
    fi
}

assert_contains() {
    if [[ -n "${ZSH_VERSION}" ]]; then
        local test_name=${funcstack[2]}
    else
        local test_name=${FUNCNAME[1]}
    fi
    local actual="${1%$$\n}"
    local expected="${2}"

    if [[ ! "${actual}" == *"${expected}"* ]]; then
        echo "Test case '${test_name}' failed; ! (lhs contains rhs)"
        diff --color=always <(echo "${actual}") <(echo "${expected}")
        return 1
    else
        return 0
    fi
}

assert_starts_with() {
    if [[ -n "${ZSH_VERSION}" ]]; then
        local test_name=${funcstack[2]}
    else
        local test_name=${FUNCNAME[1]}
    fi
    local actual="${1%$\'\n\'}"
    local expected="${2}"

    if [[ ! "${actual}" == "${expected}"* ]]; then
        echo "Test case '${test_name}' failed; ! (lhs starts_with rhs)"
        diff --color=always <(echo "${actual}") <(echo "${expected}")
        return 1
    else
        return 0
    fi
}

assert_ends_with() {
    if [[ -n "${ZSH_VERSION}" ]]; then
        local test_name=${funcstack[1]}
    else
        local test_name=${FUNCNAME[1]}
    fi
    local actual="${1%$\'\n\'}"
    local expected="${2}"

    if [[ ! "${actual}" == *"${expected}" ]]; then
        echo "Test case '${test_name}' failed; ! (lhs ends_with rhs)"
        diff --color=always <(echo "${actual}") <(echo "${expected}")
        return 1
    else
        return 0
    fi
}

run_local_tests() {
    if [[ -z "${ZSH_VERSION}" ]]; then
        local -a names=($(declare -F | cut -d ' ' -f 3))
    else
        local -a names=($(print -l ${(ok)functions[(I)[^_]*]}))
    fi
    local name

    local total=0
    local failed=0
    for name in ${names[@]}; do
        if [[ "$name" =~ ^test_ ]]; then
            if ! $name; then
                failed=$((failed + 1))
            fi
            total=$((total + 1))
        fi
    done
    local success=$((total - failed))
    echo "Run local tests; total: ${total}, succeeded: ${success}, failed: ${failed}"
    
}

__test_single_wrapper() {
    local prev_level=${SHLOG_LEVEL}
    local max_level=$1
    local no_color=$2
    local level_fn=$3
    local message="${4}"
    local ends_with_prefix="${5}"

    SHLOG_LEVEL=${max_level}
    SHLOG_NOCOLOR=${no_color}
    local output=$(${level_fn} "${message}")
    SHLOG_LEVEL=${prev_level}

    assert_ends_with "$output" "${ends_with_prefix}${message}"
    return $?
}

test_log_critical_no_color() {
    __test_single_wrapper \
        6 1 log_critical \
        "arg, I'm about to explode!" \
        " [critical] 🧨 "
    return $?
}

test_log_critical_supressed_no_color() {
    __test_single_wrapper \
        6 1 log_critical "" ""
    return $?
}

test_log_error_no_color() {
    __test_single_wrapper \
        6 1 log_error \
        "arg, something really bad happened!" \
        " [error] 🔥 "
    return $?
}

test_log_error_supressed_no_color() {
    __test_single_wrapper \
        6 1 log_error "" ""
    return $?
}

test_log_warning_no_color() {
    __test_single_wrapper \
        6 1 log_warning \
        "something kinda bad happened" \
        " [warning] 🛑 "
    return $?
}

test_log_warning_supressed_no_color() {
    __test_single_wrapper \
        6 1 log_warning "" ""
    return $?
}

test_log_info_no_color() {
    __test_single_wrapper \
        6 1 log_info \
        "something happened" \
        " [info] 💬 "
    return $?
}

test_log_info_supressed_no_color() {
    __test_single_wrapper \
        0 1 log_warning "" ""
    return $?
}

test_log_debug_no_color() {
    __test_single_wrapper \
        6 1 log_debug \
        "did something happen?" \
        " [debug] 🐞 "
    return $?
}

test_log_debug_supressed_no_color() {
    __test_single_wrapper \
        0 1 log_debug "" ""
    return $?
}

test_log_trace_no_color() {
    __test_single_wrapper \
        6 1 log_trace \
        "made it this far" \
        " [trace] 🔬 "
    return $?
}

test_log_trace_supressed_no_color() {
    __test_single_wrapper \
        0 1 log_trace "" ""
    return $?
}

test_log_trace_in_scope_no_color() {
    SHLOG_LEVEL=6
    SHLOG_NOCOLOR=1

    if [[ -n "${ZSH_VERSION}" ]]; then
        local test_name=${funcstack[1]}
    else
        local test_name=${FUNCNAME[0]}
    fi

    local output=$( \
        log_scope_enter "${test_name}" && \
        log_scope_enter inner && \
        log_trace "made it this far" && \
        log_scope_exit inner && \
        log_scope_exit "${test_name}" \
    )
    output="${output[*]}"

    SHLOG_LEVEL=0

    assert_contains "${output}" " test_log_trace_in_scope_no_color [trace] 🔬 entered: ${test_name}" || \
        assert_contains "${output}" " test_log_trace_in_scope_no_color::inner [trace] 🔬 entered: inner" || \
        assert_contains "${output}" " test_log_trace_in_scope_no_color::inner [trace] 🔬 made it this far" || \
        assert_contains "${output}" " test_log_trace_in_scope_no_color::inner [trace] 🔬 exiting: inner" || \
        assert_contains "${output}" " test_log_trace_in_scope_no_color [trace] 🔬 exiting: ${test_name}"
    return $?
}

SHLOG_LEVEL=6
SHLOG_NOCOLOR=0
log_scope_enter shlog-tests
log_scope_enter with-color
log_critical "arg, I'm about to explode!"
log_error "arg, something really bad happened!"
log_warning "arg, something kinda bad happened!"
log_info "something happened!"
log_debug "did something happened?"
log_trace "made it this far"
log_scope_exit with-color
SHLOG_NOCOLOR=1
log_scope_enter no-color
log_critical "arg, I'm about to explode!"
log_error "arg, something really bad happened!"
log_warning "arg, something kinda bad happened!"
log_info "something happened!"
log_debug "did something happened?"
log_trace "made it this far"
log_scope_exit no-color
log_scope_exit shlog-tests
SHLOG_LEVEL=0

run_local_tests