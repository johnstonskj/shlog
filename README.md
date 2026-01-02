# Shell Logging utils

This repository is a Zsh plugin, and wrapper script for Bash, providing a set
of functions for logging.

[![Apache-2.0 License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![MIT License](https://img.shields.io/badge/license-mit-118811.svg)](https://opensource.org/license/mit)
[![GitHub stars](https://img.shields.io/github/stars/johnstonskj/zsh-shlog-plugin.svg)](<https://github.com/johnstonskj/zsh-shlog-plugin/stargazers>)

These functions provides the common set of level-based logging functions as
well as some functions for interactive messages and nested log scopes.

| Shell | Version | O/S        |
|-------|---------|------------|
| bash  | 5.3.8   | macos 26.1 |
| zsh   | 5.9     | macos 26.1 |

## Install

### Zsh

Use your favorite plugin manager with the repository `johnstonskj/shlog`.

For manual installation follow the instructions for Bash.

### Bash

```bash
❱ git clone https://github.com/johnstonskj/shlog ${XDG_DATA_HOME}/shlog
❱ source ${XDG_DATA_HOME}/shlog/shlog.bash
```

It is common to include a more complex block, as shown below, at the head of
scripts using shlog.

``` bash
function init_logging {
    if ! typeset -f log_critical >/dev/null; then
        SHLOG_SOURCE="${XDG_DATA_HOME:-$HOME/.local/share/shlog}/shlog.bash"
        if [[ -f ${SHLOG_SOURCE} ]]; then
            source ${SHLOG_SOURCE}
        else
            echo "Error: logging script ${SHLOG_SOURCE} not found."
        fi
    fi
}
```

## Example

The following is a simple script to capture hierarchical calls.

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
2023-34-07T19:11:01.1699385641Z [info] 💬 calling first
2023-34-07T19:11:01.1699385641Z first [trace] 🔬 entered: first
2023-34-07T19:11:01.1699385641Z first [info] 💬 calling second
2023-34-07T19:11:01.1699385641Z first [trace] 🔬 enter: second
2023-34-07T19:11:01.1699385641Z first::second [warning] 🛑 doing something
2023-34-07T19:11:01.1699385641Z first::second [trace] 🔬 exiting: second
2023-34-07T19:11:01.1699385641Z first [trace] 🔬 exiting: first
2023-34-07T19:11:01.1699385641Z [info] 💬 all done
```

## Functions

### logging

```bash
function log(level, ...)
```

This function takes a log level, a number between 1 and 6, and any other
parameters are assumed to be the message text. If the log level is less than
or equal to the current logging level (see environment variables below) a log
message is emitted. The log function will call the current formatting function
from the environment variable `SHLOG_FORMATTER`.

Additionally a set of functions exist for each log level that call `log` in
turn. Lastly, a function named `log_panic` is provided that issues an error
log message but will also exit the process with the provided `exit-code`.

```bash
function log_panic(exit-code, ...)
function log_critical(...)
function log_error(...)
function log_warning(...)
function log_info(...)
function log_debug(...)
function log_trace(...)
```

### Log Scopes

TBD

Log scope names MUST be simple symbols, they start with an ASCII character
followed by a sequence of ASCII characters, numbers or an underscore or
hyphen. The functions below will use the longest symbol at the start of the
`scope-name` string.

```bash
function log_scope_enter(scope-name)
```

```bash
function log_scope_exit(scope-name, status-code?)
```

### Utilities

ANSI color management functions. The function `ansi_display_attrs` takes a
list of [https://en.wikipedia.org/wiki/ANSI_escape_code#Select_Graphic_Rendition_parameters](Select Graphic Rendition)
(SGR) parameter codes. Each code may either be an integer, or a string with
semi colon separated integers.

```bash
function ansi_display_attrs(code...)
function mute_color()
function reset_color()
```

Level-related values.

```bash
function message_level_color(level)
function message_level_icon(level)
function message_level_name(level)
```

Log formatters, see below for details.

```bash
function log_formatter_default(tstamp scopes level name icon ...)
function log_formatter_friendly(tstamp scopes level name icon ...)
function log_formatter_json(tstamp scopes level name icon ...)
```

Debugging function for weird logging configuration issues.

```bash
function log_shlog_settings()
```

## Environment Variables

| Name              | Default                 | Description                                            |
|-------------------|-------------------------|--------------------------------------------------------|
| `SHLOG_LEVEL`     | `0` (off)               | The maximum logging level [1]                          |
| `SHLOG_NOCOLOR`   | `0` (color)             | If non-empty, and non-zero, turn off coloring messages |
| `SHLOG_FORMATTER` | `log_formatter_default` | The name of a formatter function                       |

Notes:

1. Only messages whose level is less than or equal to this value will be output.

## Log Entry Formatters

A formatter is a function responsible for actually outputting the entry. The
default formatter function is named `log_formatter_default` but may be
overridden using the environment variable `SHLOG_FORMATTER`. The parameters
provided to a formatter are as follows.

| # | Name          | Type                   | Description.                 |
|---|---------------|------------------------|------------------------------|
| 1 | `timestamp`   | integer                | in Epoch seconds             |
| 2 | `scope_stack` | space-separated string | an array of scope names      |
| 3 | `level`       | integer                | the log level                |
| 4 | `level_name`  | string                 | the log level's display name |
| 5 | `level_icon`  | Unicode character.     | the log level's icon         |
| 6 | `message`     | string                 | message arguments to `log`   |

### Default Formatter

As seen in the example above, the log message format contains the following components:

1. Current date-time in ISO-8601 format, and with timezone adjusted to UTC in a muted color.
2. The scope stack (optional) with scope names separated by "::" values.
3. The log level name within "[" and "]", colored according to level.
4. The log icon character.
5. The log message, also colored according to level.

### Human-friendly Formatter

The alternative formatter `friendly` outputs more verbose log entries, which are nice if the log level is set to just
errors but can get unwieldy if not.

```text
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

### JSON-Lines Formatter

The `json` formatter outputs each log entry as a JSON object, with the core
parameters included as well as the level name from the `level_names` argument.
The `scopes` attribute is optional, but note that it is reversed in order to
act more stack-like when parsing.

```json
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

## License(s)

The contents of this repository are made available under the following
licenses:

### Apache-2.0

> ```text
> Copyright 2025 johnstonskj <johnstonskj@gmail.com>
> 
> Licensed under the Apache License, Version 2.0 (the "License");
> you may not use this file except in compliance with the License.
> You may obtain a copy of the License at
> 
>     http://www.apache.org/licenses/LICENSE-2.0
> 
> Unless required by applicable law or agreed to in writing, software
> distributed under the License is distributed on an "AS IS" BASIS,
> WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
> See the License for the specific language governing permissions and
> limitations under the License.
> ```

See the enclosed file [LICENSE-Apache](https://github.com/johnstonskj/zsh-shlog-plugin/blob/main/LICENSE-Apache).

### MIT

> ```text
> Copyright 2025 johnstonskj <johnstonskj@gmail.com>
> 
> Permission is hereby granted, free of charge, to any person obtaining a copy
> of this software and associated documentation files (the “Software”), to deal
> in the Software without restriction, including without limitation the rights to
> use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
> the Software, and to permit persons to whom the Software is furnished to do so,
> subject to the following conditions:
> 
> The above copyright notice and this permission notice shall be included in all
> copies or substantial portions of the Software.
> 
> THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
> INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
> PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
> HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
> OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
> SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
> ```

See the enclosed file [LICENSE-MIT](https://github.com/johnstonskj/zsh-shlog-plugin/blob/main/LICENSE-MIT).
