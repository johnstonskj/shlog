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
         End

    End

    Describe 'using the friendly formatter'
        Before 'SHLOG_FORMATTER=log_formatter_friendly'
        date_time() {
            printf "Monday, December 29 at 09:06:09 AM"
        }

        Describe 'with filter enabled and color disabled'
            Before 'SHLOG_LEVEL=6'
            Before 'SHLOG_NOCOLOR=1'

            Describe 'calling log_critical'
                It "outputs a human-readable message"
                    When call log_critical "arg, I'm about to explode!"
                    The lines of stdout should equal 3
                    The line 1 of output should equal "On $(date_time),"
                    The line 2 of output should equal "    a critical error occurred:"
                    The line 3 of output should equal "        arg, I'm about to explode!"
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
                It "outputs a JSON line"
                    When call log_critical "arg, I'm about to explode!"
                    The output should equal "{ \"timestamp\": 1767027969, \"level\": 1,  \"levelName\": \"critical\", \"levelIcon\": \"🧨\", \"message\": \"arg, I'm about to explode!\" }"
                End
            End
        End
    End

End