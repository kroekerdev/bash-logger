# Bash Logger

A robust logging framework specifically designed for Bash scripts. By
incorporating this logging framework, Bash scripts can easily implement
comprehensive logging capabilities, empowering developers with enhanced
debugging and monitoring capabilities throughout the script's lifecycle.

## Compatibility

Bash Logger has been tested and verified to work with the following versions:

- Bash 5.2

Please note that Bash Logger should work with Bash 4.0 and above, but full
compatibility is guaranteed with the specified versions or later.

## Features

- **Flexible Logging Levels:** Offers multiple logging levels, including `DEBUG`,
`INFO`, `WARNING`, `ERROR`, and `CRITICAL`. Developers can easily set their
desired logging level to filter out less important messages and focus on the
relevant information.

- **Customizable Log Formatting:** Supports customizable log formatting, allowing
developers to log messages in a brief or verbose manner, including their exact
location.

- **Configurable Output Destinations:** Supports simultaneous logging to both the
console and a file. Developers have the flexibility to choose whether to log 
to the console, redirect the output to a specific log file, or utilize both
options.

- **Error Handling and Tracing:** Provides built-in error handling and tracing
capabilities. When an error occurs, it captures the error details, including
the offending command, exact location, and exit status. This enables developers
to quickly identify the source of the error.

- **Easy Integration:** Designed for seamless integration into existing Bash
scripts. Developers can enhance their scripts quickly by adding logging
statements through simple function calls, without the need for complex setup or
extensive modifications.

## Table of Contents

- [Bash Logger](#bash-logger)
  - [Compatibility](#compatibility)
  - [Features](#features)
  - [Functions](#functions)
    - [`set_log_level`](#set_log_level)
    - [`set_log_formatter`](#set_log_formatter)
    - [`set_log_file`](#set_log_file)
    - [`set_suppress_console`](#set_suppress_console)
    - [`log`](#log)
    - [`trap_error`](#trap_error)
    - [`check_status`](#check_status)
  - [Usage](#usage)
    - [Set Log Level](#set-log-level)
    - [Set Log Formatter](#set-log-formatter)
    - [Set Log File](#set-log-file)
    - [Set Suppress Console](#set-suppress-console)
    - [Log](#log-1)
    - [Trap Error](#trap-error)
    - [Check Status](#check-status)
  - [Contributions](#contributions)
  - [License](#license)
  - [Author](#author)

## Functions

### `set_log_level`

Set the log level to the specified value.

Parameters:
  > `log_level`: The log level to set.
  >> `-c`, `--critical`, `CRITICAL`: Set the log level to critical.

  >> `-e`, `--error`, `ERROR`: Set the log level to error.

  >> `-w`, `--warning`, `WARNING`: Set the log level to warning.

  >> `-i`, `--info`, `INFO`: Set the log level to info.

  >> `-d`, `--debug`, `DEBUG`: Set the log level to debug.

  > `-x`, `--export`: Export to the environment.

Return:
  > `None`

### `set_log_formatter`

Set the log formatter to the specified value.

Parameters:
  > `log_formatter`: The log formatter to set.
  >> `-b`, `--brief`, `BRIEF`: Set the log formatter to brief mode.

  >> `-v`, `--verbose`, `VERBOSE`: Set the log formatter to verbose mode.

  > `-x`, `--export`: Export to the environment.

Return:
  > `None`

### `set_log_file`

Set the log file path to the specified value.

Parameters:
  > `log_file`: The path of the log file to set.

  > `-x`, `--export`: Export to the environment.

Return:
  > `None`

### `set_suppress_console`

Sets the flag to suppress console output to the specified value.

Parameters:
  > `-s`, `--suppress`, `TRUE`: Suppress console output.

  > `-ns`, `--no-suppress`, `FALSE`: Do not suppress console output.

  > `-x`, `--export`: Export to the environment.

Return:
> `None`

### `log`

Log a message with the specified log level and message.

Parameters:
  > `log_level`: The log level of the message.
  >> `-c`, `--critical`, `CRITICAL`: Set the log level to critical.

  >> `-e`, `--error`, `ERROR`: Set the log level to error.

  >> `-w`, `--warning`, `WARNING`: Set the log level to warning.

  >> `-i`, `--info`, `INFO`: Set the log level to info.

  >> `-d`, `--debug`, `DEBUG`: Set the log level to debug.

  > `message`: The log message to be logged.

  > `last_command`: (Optional) The last command executed.

  > `exit_code`: (Optional) The exit code of the last command executed.

  > `-b`, `--brief`, `BRIEF`: (Optional) Set the log formatter to brief mode.

  > `-v`, `--verbose`, `VERBOSE`: (Optional) Set the log formatter to verbose
  mode.

  > `-s`, `--suppress`, `TRUE`: (Optional) Suppress console output.

  > `-ns`, `--no-suppress`, `FALSE`: (Optional) Do not suppress console output.

  > `-f`, `--file`: (Optional) Read the message from a file.

Return:
> `None`

### `trap_error`

Set up error trapping to log errors.

Parameters:
> `None`

Return:
> `None`

Note:
- Creates global temporary file 'err' for redirecting error messages.

### `check_status`

If the return value is non-zero, log an error message, and terminate the
function or shell with an exit status of 1.

Parameters:
> `return_value`: The return value to check.

Return:
> `0` if the return value is zero, otherwise terminate the function or shell
with an exit status of `1`.

## Usage

Source the `bash_logger.sh` script in your Bash script by using the `source`
or `.` command:

```bash
source bash_logger.sh
```

### Set Log Level

The log levels define the severity of the logged messages. Below is a list of
the log levels in increasing order of severity:

1. DEBUG
2. INFO
3. WARNING
4. ERROR
5. CRITICAL

By default, the log level is set to ERROR.

To modify the log level, you can use the `set_log_level` function. Here is an
example of how to set it to DEBUG:

```bash
set_log_level --debug
```

If you want to export the log level to the environment, you can use the
following command:

```bash
set_log_level --export --debug
```

### Set Log Formatter

The format of the log messages is determined by the log formatter. Here are
the available formatters:

- BRIEF: Prints only the log message.
- VERBOSE: Prints detailed information about the log message, including the
script name, function name, and line number. If provided, it also prints the
last command executed and its exit code.

By default, the log formatter is set to VERBOSE.

To adjust the log formatter, you can use the `set_log_formatter` function.
Here's an example of setting it to BRIEF:

```bash
set_log_formatter --brief
```

If you want to export the log formatter to the environment, you can use the
following command:

```bash
set_log_formatter --export --brief
```

### Set Log File

Set log file is used to specify the path where log messages will be written. If
a log file is not provided, the messages will be displayed only on the console.

By default, the log file path is not set.

To set the log file, you can utilize the `set_log_file` function. Here's an
example:

```bash
set_log_file /path/to/log/file.log
```

If you want to export the log file path to the environment, you can use the
following command:

```bash
set_log_file --export /path/to/log/file.log
```

### Set Suppress Console

By default, log messages are displayed on both the console and the log file (if
a log file path has been specified).

By default, the suppress console is set to FALSE.

To suppress console output, you can use the `set_suppress_console` function.
Here's an example:

```bash
set_suppress_console --suppress
```

If you want to export the console suppression to the environment, you can use
the following command:

```bash
set_suppress_console --export --suppress
```

To remove the console suppression:

```bash
set_suppress_console --no-suppress
```

```bash
set_suppress_console --export --no-suppress
```

### Log

To log a message, you can simply provide its log level and the message using
the `log` function. Here are some examples:

```bash
log --critical "This is a critical message."
```

```bash
log --error "This is an error message."
```

```bash
log --warning "This is a warning message."
```

```bash
log --info "This is an info message."
```

```bash
log --debug "This is a debug message."
```

The log formatter can be temporarily overridden. For instance:

```bash
log --brief --info "This is a brief informational message."
```

```bash
log --verbose --info "This is a verbose informational message."
```

Console suppression can also be temporarily overridden. For example:

```bash
log --suppress --warning "This is a suppressed warning message."
```

```bash
log --no-suppress --warning "This is an unsuppressed warning message."
```

### Trap Error

To capture an error and handle it, you can utilize the `trap_error` function.
Here's an example:

```bash
trap_error
null_command 2>$err
```

If the trap is triggered, an error message, along with the command and
its exit status, will be logged. Subsequently, the current function or shell
will receive an exit status of `1`.

Note that the `trap_error` function always provides verbose logging for error
messages.

### Check Status

To validate the exit status of a command, function, or sub-shell, you can use
the `check_status` function. Here's an example that checks the return value of
a sub-shell:

```bash
(
  trap_error
  null_command 2>$err
); check_status $?
```

If the exit status of the sub-shell is non-zero, a critical message, along with
the exit status, will be logged. Subsequently, the current shell will receive
an exit status of `1`.

## Contributions

Contributions to Bash Logger are welcome. If you find any issues or have
suggestions for improvements, please submit them through the project's 
[GitHub repository](https://github.com/kroekerdev/bash-logger). You can clone
the repository, make changes, and submit a pull request.

When contributing, please follow a similar coding style to ensure consistency
throughout the codebase.

It is also encouraged to create unit tests for any new functionality or
changes. Unit tests help ensure the stability of Bash Logger and validate
that the intended functionality is working as expected.

Thank you for your interest in contributing to Bash Logger!

## License

Bash Logger is released under the MIT License. For more details, see the
[LICENSE](LICENSE) file.

## Author

Bash Logger was created by Nicolas A. Kroeker (kroekerdev).
