# Shell Logging utils

This simple script provides a set of functions for logging that can be used in Zsh and Bash. It
provides the common set of level-based logging functions as well as some functions for interactive messages and nested
log scopes.

| Shell | Version | O/S |
|-------|---------|-----|
| bash  | 3.2.57  | macos 13.5.2 |
| bash  | 5.2.15  | macos 13.5.2 |
| sh    | (as bash) | (as bash) |
| zsh   | 5.9     | macos 13.5.2 |

## Example

The complete source for the following example is in [example/simple.sh](example/simple.sh).

```bash
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
```

This results in the following trace (using the default formatting function).

```console
2023-34-07T19:11:01.1699385641Z [info] calling first
2023-34-07T19:11:01.1699385641Z /first [trace] entered: first
2023-34-07T19:11:01.1699385641Z /first [info] calling second
2023-34-07T19:11:01.1699385641Z /first [trace] enter: second
2023-34-07T19:11:01.1699385641Z /first/second [warning] doing something
2023-34-07T19:11:01.1699385641Z /first/second [trace] exiting: second
2023-34-07T19:11:01.1699385641Z /first [trace] exiting: first
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
function log(level, ...)
```

This function takes a log level, a number between 1 and 6, and any other parameters are assumed to be the message text.
If the log level is less than or equal to the current logging level (see environment variables below) a log message is
emitted. The log function will call the current formatting function from the environment variable `SHLOG_FORMATTER`.

Additionally a set of functions exist for each log level that call `log` in turn. Lastly, a function named `log_panic` is
provided that issues an error log message but will also exit the process with the provided `exit-code`.

```bash
function log_panic(exit-code, ...)
function log_error (...)
function log_warning(...)
function log_info(...)
function log_debug(...)
function log_trace(...)
```

### Log Scopes

TBD

Log scope names MUST be simple symbols, they start with an ASCII character followed by a sequence of ASCII characters,
numbers or an underscore or hyphen. The functions below will use the longest symbol at the start of the `scope-name` string.

```bash
function log_scope_enter(scope-name)
```

```bash
function log_scope_exit(scope-name, status-code?)
```

### Interactive Messages

TBD

```bash
function msg_success(...)
```

```bash
function msg_warning(...)
function msg_error(...)
```

## Log Entry Formatters

A formatter is a function responsible for actually outputting the entry. The default formatter function is named
`log_formatter_default` but may be overridden using the environment variable `SHLOG_FORMATTER`. 

```bash
function log_formatter_<name>(timestamp, scope_stack, level, level_names, message)
```

- `timestamp` -- in Epoch seconds.
- `scope_stack` -- an array of scope names.
- `level` -- the log level as an integer.
- `level_names` -- an array of level names, indexed by level.
- `message` -- a single string with all the arguments to `log`.

### Formatter `default`

As seen in the example above, the log message format contains the following components:

1. Current date-time in ISO-8601 format, and with timezone adjusted to UTC in a muted color.
2. The scope stack (optional) with scope names separated by ">>" values.
3. The log level name within "[" and "]", colored according to level.
4. The log message, also colored according to level.

### Formatter: `friendly`
The alternative formatter `friendly` outputs more verbose log entries, which are nice if the log level is set to just
errors but can get unwieldy if not.

```console
On Thursday, November  9 at 11:31:49 AM
    To help with debugging:
    shlog loaded; SHLOG_LEVEL=6
On Thursday, November  9 at 11:31:49 AM
    We wanted you to know:
    calling first
On Thursday, November  9 at 11:31:49 AM
    In the scope/first
    To help with tracing:
    entered: first
On Thursday, November  9 at 11:31:49 AM
    In the scope /first
    We wanted you to know:
    calling second
On Thursday, November  9 at 11:31:49 AM
    In the scope /first/second
    To help with tracing:
    entered: second
On Thursday, November  9 at 11:31:49 AM
    In the scope /first/second
    A warning was issued:
    doing something
On Thursday, November  9 at 11:31:49 AM
    In the scope /first/second
    To help with tracing:
    exiting: second
On Thursday, November  9 at 11:31:49 AM
    In the scope /first
    To help with tracing:
    exiting: first
On Thursday, November  9 at 11:31:49 AM
    We wanted you to know:
    all done
```

### Formatter: `json`

The `json` formatter outputs each log entry as a JSON object, with the core parameters included as well as the level name
from the `level_names` argument. The `scopes` attribute is optional, but note that it is reversed in order to act more
stack-like when parsing.

``` console
{ "timestamp": 1699560854, "level": 4, "levelName": debug, "message": "shlog loaded; SHLOG_LEVEL=6" }
{ "timestamp": 1699560854, "level": 3, "levelName": info, "message": "calling first" }
{ "timestamp": 1699560854, "scopes": [ "first" ], "level": 5, "levelName": trace, "message": "entered: first" }
{ "timestamp": 1699560854, "scopes": [ "first" ], "level": 3, "levelName": info, "message": "calling second" }
{ "timestamp": 1699560854, "scopes": [ "second", "first" ], "level": 5, "levelName": trace, "message": "entered: second" }
{ "timestamp": 1699560854, "scopes": [ "second", "first" ], "level": 2, "levelName": warning, "message": "doing something" }
{ "timestamp": 1699560854, "scopes": [ "second", "first" ], "level": 5, "levelName": trace, "message": "exiting: second" }
{ "timestamp": 1699560854, "scopes": [ "first" ], "level": 5, "levelName": trace, "message": "exiting: first" }
{ "timestamp": 1699560854, "level": 3, "levelName": info, "message": "all done" }
```

## Environment Variables

- **`SHLOG_LEVEL`** -- The level of logging; only messages whose level is less than or equal to this value will be output.
* **`SHLOG_NOCOLOR`** -- If set to any non-empty value it turns of coloring of the output messages.
* **`SHLOG_FORMATTER`** -- Default value is `default`.

## Testing For Logging

The following function will test whether the `shlog` script has been run successfully and the logging functions are available.

``` bash
function logging_present {
    typeset -f log_critical >/dev/null
}
```

It is common to include a more complex block, as shown below, at the head of scripts using shlog. 

``` bash
function init_logging {
    if ! typeset -f log_critical >/dev/null; then
        SHLOG_SOURCE="${XDG_DATA_HOME:-$HOME/.local/share/shlog}/shlog.sh"
        if [[ -f ${SHLOG_SOURCE} ]]; then
            source ${SHLOG_SOURCE}
        else
            echo "Error: logging script ${SHLOG_SOURCE} not found."
        fi
    fi
}
```

## Changelog

TBD
