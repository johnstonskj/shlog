# Shell Logging utils

This simple script provides a set of functions for logging that can be used in Zsh, and to some extent in Bash. 

## Example

The complete source for the following example is in [example/simple.sh](example/simple.sh).

```bash
function first {
    log_scope_enter "first"
    log_info "calling second"
    second
    log_scope_exit "first"
}

function second {
    log_scope_enter "second"
    log_warning "doing something"
    log_scope_exit "second"
}

log_info "calling first"
first
```

This results in the following trace.

```
2023-34-07T19:11:01.1699385641Z [info] calling first
2023-34-07T19:11:01.1699385641Z [trace] enter: first
2023-34-07T19:11:01.1699385641Z first [info] calling second
2023-34-07T19:11:01.1699385641Z first [trace] enter: second
2023-34-07T19:11:01.1699385641Z first >> second [warning] doing something
2023-34-07T19:11:01.1699385641Z first >> second [trace] exit: second
2023-34-07T19:11:01.1699385641Z first [trace] exit: first
2023-34-07T19:11:01.1699385641Z [info] all done
```

## Installation

Installing this script is basically to link a copy of the script from the local repository clone into the directory
identified by the standard `XDG_DATA_HOME` environment variable. If this variable is not set, the fallback location
`~/.local/share/shlog` will be used.

```bash
❯ ./install.sh
```

Removing an existing installed script may be accomplished with the same installer.

```bash
❯ ./install.sh remove
```

## Functions

### logging

```bash
log(level, ...)
```

This function takes a log level, a number between 1 and 6, and any other parameters are assumed to be the message text.
If the log level is less than or equal to the current logging level (see environment variables below) a log message is
emitted. The log message format contains the following components:

1. Current date-time in ISO-8601 format, and with timezone adjusted to UTC.
2. The scope stack (optional) with scope names separated by ">>" values.
3. The log level name within "[" and "]".
4. The log message.

Additionally a set of functions exist for each log level that call `log` in turn. Lastly, a function named `log_panic` is
provided that issues an error log message but will also exit the process with the provided `exit-code`.

```bash
log_panic(exit-code, ...)
log_error (...)
log_warning(...)
log_info(...)
log_debug(...)
log_trace(...)
```

### Log Scopes

TBD

```bash
log_scope_enter(scope-name)
```

```bash
log_scope_exit(scope-name)
```

### Interactive Messages

TBD

```bash
msg_success ...
```

```bash
msg_warning ...
msg_error ...
```

## Environment Variables

- **`SHLOG_LEVEL`** -- The level of logging.
* **`SHLOG_NOCOLOR`** -- TBD.

## Testing For Logging

The following function will test whether the `shlog` script has been run successfully and the logging functions are available.

``` bash
function logging_present {
    typeset -f log_critical >/dev/null
}
```

It is common to include a more complex block, as shown below, at the head of scripts using shlog. 

``` bash
if ! typeset -f log_critical >/dev/null; then
    SHLOG_SOURCE="${XDG_DATA_HOME:-$HOME/.local/share/shlog}/shlog.sh"
    if [[ -f ${SHLOG_SOURCE} ]]; then
        source ${SHLOG_SOURCE}
    else
        echo "Error: logging script ${SHLOG_SOURCE} not found."
    fi
fi
```
