# -*- mode: sh; eval: (sh-set-shell "bash") -*-

#if [[ -n "${ZSH_VERSION}" ]]; then
#    source "${PWD}/shlog.plugin.zsh"
#else
    source "${PWD}/shlog.bash"
#fi

log_timestamp() {
    printf "1767027969"
}

Describe 'Library shlog'
    Before='shlog'

    fixture_log_scope() {
        log_scope_enter scope1
        log_scope_exit scope1
    }

    fixture_log_scope_nested() {
        log_info "outside scope(s)"
        log_scope_enter scope1
        log_info "inside scope"
        log_scope_enter scope2
        log_info "inside inner scope"
        log_scope_exit scope2
        log_scope_exit scope1
    }

    Describe 'using the default formatter'
        Before 'SHLOG_FORMATTER=log_formatter_default'
        date_time() {
            printf "2025-12-29T17:06:09Z"
        }

        Describe 'with filter enabled and color disabled'
            Before 'SHLOG_LEVEL=6'
            Before 'SHLOG_NOCOLOR=1'

            Describe 'calling log_critical'
                It "outputs $(date_time) [critical] 🧨 arg, I'm about to explode!"
                    When call log_critical "arg, I'm about to explode!"
                    The output should equal "$(date_time) [critical] 🧨 arg, I'm about to explode!"
                End
            End

            Describe 'calling log_error'
                It "outputs $(date_time) [error] 🔥 arg, something really bad happened!"
                    When call log_error "arg, something really bad happened!"
                    The output should equal "$(date_time) [error] 🔥 arg, something really bad happened!"
                End
            End

            Describe 'calling log_warning'
                It "outputs $(date_time) [warning] 🛑 oops, something kinda bad happened"
                    When call log_warning "oops, something kinda bad happened"
                    The output should equal "$(date_time) [warning] 🛑 oops, something kinda bad happened"
                End
            End
 
            Describe 'calling log_info'
                It "outputs $(date_time) [info] 💬 something happened"
                    When call log_info "something happened"
                    The output should equal "$(date_time) [info] 💬 something happened"
                End
            End

            Describe 'calling log_debug'
                It "outputs $(date_time) [debug] 🐞 did something happen?"
                    When call log_debug "did something happen?"
                    The output should equal "$(date_time) [debug] 🐞 did something happen?"
                End
            End
 
            Describe 'calling log_trace'
                It "outputs $(date_time) [trace] 🔬 made it this far"
                    When call log_trace "made it this far"
                    The output should equal "$(date_time) [trace] 🔬 made it this far"
                End
            End

            Describe 'calling log_scope_enter and log_scope_exit'
                Before 'SHLOG[_SCOPES]=""'

                It "outputs $(date_time) scope1 [trace] 🔬 ..."
                    When call fixture_log_scope
                    The lines of stdout should equal 2
                    The line 1 of output should equal "$(date_time) scope1 [trace] 🔬 entered: scope1"
                    The line 2 of output should equal "$(date_time) scope1 [trace] 🔬 exiting: scope1"
                End
            End

            Describe 'calling nested log_scope_enter and log_scope_exit'
                Before 'SHLOG[_SCOPES]=""'

                It "outputs $(date_time) scope1::scope2 [trace] 🔬 ..."
                    When call fixture_log_scope_nested
                    The lines of stdout should equal 7
                    The line 1 of output should equal "$(date_time) [info] 💬 outside scope(s)"
                    The line 2 of output should equal "$(date_time) scope1 [trace] 🔬 entered: scope1"
                    The line 3 of output should equal "$(date_time) scope1 [info] 💬 inside scope"
                    The line 4 of output should equal "$(date_time) scope1::scope2 [trace] 🔬 entered: scope2"
                    The line 5 of output should equal "$(date_time) scope1::scope2 [info] 💬 inside inner scope"
                    The line 6 of output should equal "$(date_time) scope1::scope2 [trace] 🔬 exiting: scope2"
                    The line 7 of output should equal "$(date_time) scope1 [trace] 🔬 exiting: scope1"
                End
            End
        End

        Describe 'with filter and color disabled'
            Before 'SHLOG_LEVEL=0'
            Before 'SHLOG_NOCOLOR=1'

            Describe 'calling log_critical'
                It "does nothing"
                    When call log_critical "arg, I'm about to explode!"
                    The output should equal ""
                End
            End

            Describe 'calling log_error'
                It "does nothing"
                    When call log_error "arg, something really bad happened!"
                    The output should equal ""
                End
            End

            Describe 'calling log_warning'
                It "does nothing"
                    When call log_warning "oops, something kinda bad happened"
                    The output should equal ""
                End
            End
 
            Describe 'calling log_info'
                It "does nothing"
                    When call log_info "something happened"
                    The output should equal ""
                End
            End

            Describe 'calling log_debug'
                It "does nothing"
                    When call log_debug "did something happen?"
                    The output should equal ""
                End
            End
 
            Describe 'calling log_trace'
                It "does nothing"
                    When call log_trace "made it this far"
                    The output should equal ""
                End
            End

            Describe 'calling log_scope_enter and log_scope_exit'
                It "does nothing"
                    When call fixture_log_scope
                    The output should equal ""
                End
            End

            Describe 'calling nested log_scope_enter and log_scope_exit'
                It "does nothing"
                    When call fixture_log_scope_nested
                    The output should equal ""
                End
            End
         End

    End

    Describe 'using the friendly formatter'
        Before 'SHLOG_FORMATTER=log_formatter_friendly'
        date_time() {
            printf "Monday, December 29 at 05:06:09 PM (UTC)"
        }

        Describe 'with filter enabled and color disabled'
            Before 'SHLOG_LEVEL=6'
            Before 'SHLOG_NOCOLOR=1'

            Describe 'calling log_critical'
                It "outputs a human-readable message"
                    When call log_critical "arg, I'm about to explode!"
                    The lines of stdout should equal 3
                    The line 1 of output should equal "├ On $(date_time),"
                    The line 2 of output should equal "│ ├ a critical error occurred:"
                    The line 3 of output should equal "│ └─┤ arg, I'm about to explode! │"
                End
            End

            Describe 'calling log_scope_enter and log_scope_exit'
                It "outputs human-readable, nested, messages"
                    When call fixture_log_scope
                    The lines of stdout should equal 8
                    The line 1 of output should equal "├── On $(date_time),"
                    The line 2 of output should equal "│   ├ in the scope: ❱ scope1,"
                    The line 3 of output should equal "│   ├ to help with tracing:"
                    The line 4 of output should equal "│   └─┤ entered: scope1 │"
                    The line 5 of output should equal "├── On $(date_time),"
                    The line 6 of output should equal "│   ├ in the scope: ❱ scope1,"
                    The line 7 of output should equal "│   ├ to help with tracing:"
                    The line 8 of output should equal "│   └─┤ exiting: scope1 │"
                End
            End

            Describe 'calling nested log_scope_enter and log_scope_exit'
                It "outputs human-readable, nested, messages"
                    When call fixture_log_scope_nested
                    The lines of stdout should equal 27
                    The line  1 of output should equal "├ On $(date_time),"
                    The line  2 of output should equal "│ ├ we wanted you to know:"
                    The line  3 of output should equal "│ └─┤ outside scope(s) │"
                    The line  4 of output should equal "├── On $(date_time),"
                    The line  5 of output should equal "│   ├ in the scope: ❱ scope1,"
                    The line  6 of output should equal "│   ├ to help with tracing:"
                    The line  7 of output should equal "│   └─┤ entered: scope1 │"
                    The line  8 of output should equal "├── On $(date_time),"
                    The line  9 of output should equal "│   ├ in the scope: ❱ scope1,"
                    The line 10 of output should equal "│   ├ we wanted you to know:"
                    The line 11 of output should equal "│   └─┤ inside scope │"
                    The line 12 of output should equal "├──── On $(date_time),"
                    The line 13 of output should equal "│     ├ in the scope: ❱ scope1 ❱ scope2,"
                    The line 14 of output should equal "│     ├ to help with tracing:"
                    The line 15 of output should equal "│     └─┤ entered: scope2 │"
                    The line 16 of output should equal "├──── On $(date_time),"
                    The line 17 of output should equal "│     ├ in the scope: ❱ scope1 ❱ scope2,"
                    The line 18 of output should equal "│     ├ we wanted you to know:"
                    The line 19 of output should equal "│     └─┤ inside inner scope │"
                    The line 20 of output should equal "├──── On $(date_time),"
                    The line 21 of output should equal "│     ├ in the scope: ❱ scope1 ❱ scope2,"
                    The line 22 of output should equal "│     ├ to help with tracing:"
                    The line 23 of output should equal "│     └─┤ exiting: scope2 │"
                    The line 24 of output should equal "├── On $(date_time),"
                    The line 25 of output should equal "│   ├ in the scope: ❱ scope1,"
                    The line 26 of output should equal "│   ├ to help with tracing:"
                    The line 27 of output should equal "│   └─┤ exiting: scope1 │"
                End
            End
        End
    End

    Describe 'using the json formatter'
        Before 'SHLOG_FORMATTER=log_formatter_json'

        Describe 'with filter enabled'
            Before 'SHLOG_LEVEL=6'

            Describe 'calling log_critical'
                Before='log_shlog_settings'
                It "outputs a JSON formatted object"
                    When call log_critical "arg, I'm about to explode!"
                    The output should equal "{ \"timestamp\": 1767027969, \"level\": 1, \"levelName\": \"critical\", \"levelIcon\": \"🧨\", \"message\": \"arg, I'm about to explode!\" }"
                End
            End

            Describe 'calling log_scope_enter and log_scope_exit'
                It "outputs JSON formatted objects"
                    When call fixture_log_scope
                    The lines of stdout should equal 2
                    The line 1 of output should equal "{ \"timestamp\": 1767027969, \"scopes\": [ \"scope1\" ], \"level\": 6, \"levelName\": \"trace\", \"levelIcon\": \"🔬\", \"message\": \"entered: scope1\" }"
                    The line 2 of output should equal "{ \"timestamp\": 1767027969, \"scopes\": [ \"scope1\" ], \"level\": 6, \"levelName\": \"trace\", \"levelIcon\": \"🔬\", \"message\": \"exiting: scope1\" }"
                End
            End

            Describe 'calling nested log_scope_enter and log_scope_exit'
                It "outputs JSON formatted objects"
                    When call fixture_log_scope_nested
                    The lines of stdout should equal 7
                    The line 1 of output should equal "{ \"timestamp\": 1767027969, \"level\": 4, \"levelName\": \"info\", \"levelIcon\": \"💬\", \"message\": \"outside scope(s)\" }"
                    The line 2 of output should equal "{ \"timestamp\": 1767027969, \"scopes\": [ \"scope1\" ], \"level\": 6, \"levelName\": \"trace\", \"levelIcon\": \"🔬\", \"message\": \"entered: scope1\" }"
                    The line 3 of output should equal "{ \"timestamp\": 1767027969, \"scopes\": [ \"scope1\" ], \"level\": 4, \"levelName\": \"info\", \"levelIcon\": \"💬\", \"message\": \"inside scope\" }"
                    The line 4 of output should equal "{ \"timestamp\": 1767027969, \"scopes\": [ \"scope2\", \"scope1\" ], \"level\": 6, \"levelName\": \"trace\", \"levelIcon\": \"🔬\", \"message\": \"entered: scope2\" }"
                    The line 5 of output should equal "{ \"timestamp\": 1767027969, \"scopes\": [ \"scope2\", \"scope1\" ], \"level\": 4, \"levelName\": \"info\", \"levelIcon\": \"💬\", \"message\": \"inside inner scope\" }"
                    The line 6 of output should equal "{ \"timestamp\": 1767027969, \"scopes\": [ \"scope2\", \"scope1\" ], \"level\": 6, \"levelName\": \"trace\", \"levelIcon\": \"🔬\", \"message\": \"exiting: scope2\" }"
                    The line 7 of output should equal "{ \"timestamp\": 1767027969, \"scopes\": [ \"scope1\" ], \"level\": 6, \"levelName\": \"trace\", \"levelIcon\": \"🔬\", \"message\": \"exiting: scope1\" }"
                End
            End
         End
    End

End