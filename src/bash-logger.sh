#!/bin/bash

# Script Name: bash-logger.sh
# Description:
#   - A robust logging framework specifically designed for Bash scripts. By
#   incorporating this logging framework, Bash scripts can easily implement
#   comprehensive logging capabilities, empowering developers with enhanced
#   debugging and monitoring capabilities throughout the script's lifecycle.
# Author:
#   - Nicolas A. Kroeker (kroekerdev)
# Date:
#   - 2023-06-01
# Version:
#   - 0.1.0
# Compatibility:
#   - Bash 4.0 and above
# License:
#   - MIT License
#
# Copyright (c) 2023 Nicolas A. Kroeker
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  printf "%s\n" 'ERROR: This script needs to be sourced, not executed directly.' >&2
  exit 1
fi

check_bash_version() {
  local current_version
  local required_version="4.0"
  
  current_version="${BASH_VERSION:0:3}"

  if (( $(echo "$current_version < $required_version" | bc -l) )); then
    echo "Error: This script requires Bash version $required_version or above."
    exit 1
  fi
}

check_bash_version

declare SUPPRESS_CONSOLE
declare -r DEFAULT_SUPPRESS_CONSOLE='FALSE'

declare LOG_LEVEL
declare -Ar LOG_LEVELS=(
  ['CRITICAL']=50
  ['ERROR']=40
  ['WARNING']=30
  ['INFO']=20
  ['DEBUG']=10
)
declare -r DEFAULT_LOG_LEVEL='ERROR'

declare LOG_FORMATTER
declare -r DEFAULT_LOG_FORMATTER='VERBOSE'

declare LOG_FILE

declare -r COLOR_RESET='\033[0m'
declare -r COLOR_WHITE='\033[1;37m'
declare -r COLOR_YELLOW='\033[1;33m'
declare -r COLOR_RED='\033[1;31m'
declare -r COLOR_GREEN='\033[1;32m'
declare -r COLOR_BOLD='\033[1m'
declare -r COLOR_CRIT_BACKGROUND='\033[1;37;41m'

declare -Ar LOG_COLORS=(
  ['CRITICAL']="${COLOR_BOLD}${COLOR_RED}${COLOR_CRIT_BACKGROUND}"
  ['ERROR']="${COLOR_RED}"
  ['WARNING']="${COLOR_YELLOW}"
  ['INFO']="${COLOR_WHITE}"
  ['DEBUG']="${COLOR_GREEN}"
)

# Function: _invalid_option
# Purpose:
#   - Handles the case of an invalid option.
# Parameters:
#   - invalid_option: The invalid option that was passed.
# Return:
#   - None
# Note:
#   - This function is meant to be used internally.
function _invalid_option() {
  local invalid_option="$1"

  printf "%s %s\n" "${FUNCNAME[1]}: invalid option --" "'$invalid_option'" >&2
}

# Function: _missing_operand
# Purpose:
#   - Handles the case of a missing operand.
# Parameters:
#   - None
# Return:
#   - None
# Note:
#   - This function is meant to be used internally.
function _missing_operand() {
  printf "%s\n" "${FUNCNAME[1]}: missing operand" >&2
}

# Function: _get_current_timestamp
# Purpose:
#   - Get the current timestamp in the format "YYYY-MM-DD HH:MM:SS".
# Parameters:
#   - None
# Return:
#   - The current timestamp as a string.
# Note:
#   - This function is meant to be used internally.
function _get_current_timestamp() {
  date +"%Y-%m-%d %H:%M:%S"
}

# Function: _should_print_log
# Purpose:
#   - Check if a log message with the given log level should be printed based
#   on the current log level.
# Parameters:
#   - log_level: The log level to check.
# Return:
#   - 0 if the log message should be printed, 1 otherwise.
# Note:
#   - This function is meant to be used internally.
function _should_print_log() {
  local log_level="$1"

  if ! [[ "${LOG_LEVELS[$log_level]}" -ge "${LOG_LEVELS[$LOG_LEVEL]}" ]]; then
    return 1
  fi

  return 0
}

# Function: _log_message
# Purpose:
#   - Log a message with the specified details.
# Parameters:
#   - log_level: The log level of the message.
#   - script_name: The name of the script where the log message originates.
#   - function_name: The name of the function where the log message originates.
#   - line_number: The line number where the log message originates.
#   - message: The log message to be logged.
#   - last_command: The last command executed before the log message.
#   - exit_code: The exit code of the last command executed.
# Return:
#   - 0 Log message was printed to both the console and file.
#   - 1 Log message was printed to the file only.
#   - 2 Log message was not printed to either the console or file.
# Note:
#   - This function is meant to be used internally.
function _log_message() {
  local log_level="$1"
  local script_name="$2"
  local function_name="$3"
  local line_number="$4"
  local message="$5"
  local last_command="$6"
  local exit_code="$7"

  local user
  local group
  local verbose_message
  local log_console_header
  local log_console_brief
  local log_console_verbose
  local log_file_verbose

  user=$(id -un)
  group=$(id -gn)

  if [[ -n $last_command && -n $exit_code ]]; then
    verbose_message="[$script_name:$function_name:$line_number] [$last_command:$exit_code] [$message]"
  else
    verbose_message="[$script_name:$function_name:$line_number] [$message]"
  fi
  
  log_console_header="[${LOG_COLORS[$log_level]}$log_level${COLOR_RESET}]"
  log_console_brief="$log_console_header $message"
  log_console_verbose="$log_console_header $verbose_message"
  log_file_verbose="[$(_get_current_timestamp)] [$log_level] [$user:$group] $verbose_message"

  if { ! _should_print_log "$log_level"; }; then
    return 2
  fi

  if [[ -n "$LOG_FILE" ]]; then
    printf "%s\n" "$log_file_verbose" >> "$LOG_FILE"
  fi

  if [[ "$SUPPRESS_CONSOLE" == 'TRUE' ]]; then
    return 1
  fi

  if [[ "$LOG_FORMATTER" == 'BRIEF' ]]; then
    printf "%b\n" "$log_console_brief" >&2
  elif [[ "$LOG_FORMATTER" == 'VERBOSE' ]]; then
    printf "%b\n" "$log_console_verbose" >&2
  fi

  return 0
}

# Function: set_log_level
# Purpose:
#   - Set the log level to the specified value.
# Parameters:
#   - log_level: The log level to set.
#   Options:
#   -c|--critical|CRITICAL: Set the log level to critiical.
#   -e|--error|ERROR: Set the log level to error.
#   -w|--warning|WARNING: Set the log level to warning.
#   -i|--info|INFO: Set the log level to info.
#   -d|--debug|DEBUG: Set the log level to debug.
#   - export_log_level: (Optional) Export log level to the environment.
#   Options:
#   -x|--export: Export to the environment.
# Return:
#   - None
function set_log_level() {
  function _usage() {
    printf "%s\n" "Usage: ${FUNCNAME[1]} [option] [LEVEL]" >&2
  }

  local log_level
  local export_log_level='false'
  
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -c|--critical|CRITICAL)
        log_level='CRITICAL'
        ;;
      -e|--error|ERROR)
        log_level='ERROR'
        ;;
      -w|--warning|WARNING)
        log_level='WARNING'
        ;;
      -i|--info|INFO)
        log_level='INFO'
        ;;
      -d|--debug|DEBUG)
        log_level='DEBUG'
        ;;
      -x|--export)
        export_log_level='true'
        ;;
      *)
        _invalid_option "$1"
        _usage
        exit 1
        ;;
    esac
    shift
  done
  
  if [[ -z "$log_level" ]]; then
    _missing_operand
    _usage
    exit 1
  fi
  
  if [[ "$export_log_level" == 'true' ]]; then
    export LOG_LEVEL="$log_level"
  else
    LOG_LEVEL="$log_level"
  fi
}

# Function: set_log_formatter
# Purpose:
#   - Set the log formatter to the specified value.
# Parameters:
#   - log_formatter: The log formatter to set.
#   Options:
#   -b|--brief: Set the log formatter to brief mode.
#   -v|--verbose: Set the log formatter to verbose mode.
#   - export_log_formatter: (Optional) Export log formatter to the environment.
#   Options:
#   -x|--export: Export to the environment.
# Return:
#   - None
function set_log_formatter() {
  function _usage() {
    printf "%s\n" "Usage: ${FUNCNAME[1]} [option] [FORMATTER]" >&2
  }

  local log_formatter
  local export_formatter='false'

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -b|--brief|BRIEF)
        log_formatter='BRIEF'
        ;;
      -v|--verbose|VERBOSE)
        log_formatter='VERBOSE'
        ;;
      -x|--export)
        export_formatter='true'
        ;;
      *)
        _invalid_option "$1"
        _usage
        exit 1
        ;;
    esac
    shift
  done

  if [[ -z "$log_formatter" ]]; then
    _missing_operand
    _usage
    exit 1
  fi

  if [[ "$export_formatter" == 'true' ]]; then
    export LOG_FORMATTER="$log_formatter"
  else
    LOG_FORMATTER="$log_formatter"
  fi
}

# Function: set_log_file
# Purpose:
#   - Set the log file path to the specified value.
# Parameters:
#   - log_file: The path of the log file to set.
#   - export_log_file: (Optional) Export log file to the environment.
#   Options:
#   -x|--export: Export to the environment.
# Return:
#   - None
function set_log_file() {
  function _usage() {
    printf "%s\n" "Usage: ${FUNCNAME[1]} [option] [PATH]" >&2
  }

  local log_file
  local export_log_file='false'
  
  case "$1" in
    -x|--export)
      shift
      export_log_file='true'
      ;;
  esac

  log_file="$1"

  if [[ -z "$log_file" ]]; then
    _missing_operand
    _usage
    exit 1
  fi

  if [[ ! -f "$log_file" ]]; then
    if ! { mkdir -p "$(dirname "$log_file")" 2>/dev/null; }; then
      printf "%s %s\n" "${FUNCNAME[0]}: Failed to create directory path:" "$(dirname "$log_file")" >&2
      exit 1
    fi
    if ! { touch "$log_file" 2>/dev/null; }; then
      printf "%s %s\n" "${FUNCNAME[0]}: Insufficient write permissions:" "$log_file" >&2
      exit 1
    fi
    if ! { chown "$SUDO_USER":"$SUDO_GROUP" "$log_file" 2>/dev/null && chmod 600 "$log_file" 2>/dev/null; }; then
      printf "%s %s\n" "${FUNCNAME[0]}: Failed to take ownership:" "$log_file" >&2
      exit 1
    fi
  fi
  
  if [[ "$export_log_file" == 'true' ]]; then
    export LOG_FILE="$log_file"
  else
    LOG_FILE="$log_file"
  fi
}

# Function: set_suppress_console
# Purpose:
#   - Sets the flag to suppress console output to the specified value.
# Parameters:
#   - suppress_console: Whether console output should be suppressed.
#   Options:
#   -s|--suppress|TRUE: Suppress console output.
#   -ns|--no-suppress|FALSE: Do not suppress console output.
#   - export_log_file: (Optional) Export suppress console to the environment.
#   Options:
#   -x|--export: Export to the environment.
# Return:
#   - None
function set_suppress_console() {
  function _usage() {
    printf "%s\n" "Usage: ${FUNCNAME[1]} [option] [TRUE|FALSE]" >&2
  }
 
  local suppress_console
  local export_suppress_console='false'
  
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -s|--suppress|TRUE)
        suppress_console='TRUE'
        ;;
      -ns|--no-suppress|FALSE)
        suppress_console='FALSE'
        ;;
      -x|--export)
        export_suppress_console='true'
        ;;
      *)
        _invalid_option "$1"
        _usage
        exit 1
        ;;
    esac
    shift
  done

  if [[ -z "$suppress_console" ]]; then
    _missing_operand
    _usage
    exit 1
  fi

  if [[ "$export_suppress_console" == 'true' ]]; then
    export SUPPRESS_CONSOLE="$suppress_console"
  else
    SUPPRESS_CONSOLE="$suppress_console"
  fi
}

# Function: _set_defaults
# Purpose:
#   - Set default values for LOG_LEVEL, LOG_FORMATTER, and SUPPRESS_CONSOLE if
#   they are not already set.
# Parameters:
#   - None
# Return:
#   - None
# Note:
#   - This function is meant to be used internally.
function _set_defaults() {
  if [[ -z $LOG_LEVEL ]]; then
    set_log_level "$DEFAULT_LOG_LEVEL"
  fi
  if [[ -z $LOG_FORMATTER ]]; then
    set_log_formatter "$DEFAULT_LOG_FORMATTER"
  fi
  if [[ -z $SUPPRESS_CONSOLE ]]; then
    set_suppress_console "$DEFAULT_SUPPRESS_CONSOLE"
  fi
}

# Function: log
# Purpose:
#   - Log a message with the specified log level and message.
# Parameters:
#   - log_level: The log level of the message.
#   Options:
#   -c|--critical|CRITICAL: Set the log level to critiical.
#   -e|--error|ERROR: Set the log level to error.
#   -w|--warning|WARNING: Set the log level to warning.
#   -i|--info|INFO: Set the log level to info.
#   -d|--debug|DEBUG: Set the log level to debug.
#   - message: The log message to be logged.
#   - last_command: (Optional) The last command executed.
#   - exit_code: (Optional) The exit code of the last command executed.
#   - -b|--brief: (Optional) Set the log formatter to brief mode.
#   - -v|--verbose: (Optional) Set the log formatter to verbose mode.
#   - -s|--suppress: (Optional) Suppress console output.
#   - -ns|--no-suppress: (Optional) Do not suppress console output.
#   - -f|--file: (Optional) Read the message from a file.
# Return:
#   - None
function log() {
  function _usage() {
    printf "%s\n" "Usage: ${FUNCNAME[1]} [option] [LEVEL] [MESSAGE]" >&2
  }
  
  _set_defaults

  local args
  local log_level
  local message
  local last_command
  local exit_code
  local script_name
  local function_name
  local line_number
  local log_formatter="$LOG_FORMATTER"
  local suppress_console="$SUPPRESS_CONSOLE"

  for ((i=1; i<${#BASH_SOURCE[@]}; i++)); do
    if [[ "${BASH_SOURCE[$i]}" == "${0}" ]]; then
      script_name="${BASH_SOURCE[$i]}"
      function_name="${FUNCNAME[$i]}"
      line_number="${BASH_LINENO[$((i-1))]}"
      break
    fi
  done

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -c|--critical|CRITICAL)
        log_level='CRITICAL'
        ;;
      -e|--error|ERROR)
        log_level='ERROR'
        ;;
      -w|--warning|WARNING)
        log_level='WARNING'
        ;;
      -i|--info|INFO)
        log_level='INFO'
        ;;
      -d|--debug|DEBUG)
        log_level='DEBUG'
        ;;
      -b|--brief)
        set_log_formatter --brief
        ;;
      -v|--verbose)
        set_log_formatter --verbose
        ;;
      -s|--suppress)
        set_suppress_console --suppress
        ;;
      -ns|--no-suppress)
        set_suppress_console --no-suppress
        ;;
      -f|--file)
        message=$(<"$2")
        ;;
      *)
        args+=("$1")
        ;;
    esac
    shift
  done
  
  if [[ -z $message ]]; then
    message="${args[0]}"
  fi
  if [[ -n ${args[1]} ]]; then
    last_command="${args[1]%% 2>*}"
  fi
  if [[ -n ${args[2]} ]]; then
    exit_code="${args[2]}"
  fi

  if [[ -z $log_level || -z $message ]]; then
    _missing_operand
    _usage
    exit 1
  fi
  
  _log_message "$log_level" "$script_name" "$function_name" "$line_number" "$message" "$last_command" "$exit_code"
  set_log_formatter "$log_formatter"
  set_suppress_console "$suppress_console"
}

# Function: _err_handler
# Purpose:
#   - Handle error messages and log them as an error.
# Parameters:
#   - message: The error message to be logged.
#   - last_command: The last command executed before the error occurred.
#   - exit_code: The exit code of the last command executed.
# Return:
#   - None
# Note:
#   - This function is meant to be used internally.
function _err_handler() {
  local message="$1"
  local last_command="$2"
  local exit_code="$3"
  
  if [[ ! -s $message ]]; then
    # shellcheck disable=SC2016
    message='Message not returned or not redirected [COMMAND 2>$err]'
  fi

  log --verbose --error --file "$message" "$last_command" "$exit_code"
  exit 1
}

# Function: trap_error
# Purpose:
#   - Set up error trapping to log errors using the err_handler function.
# Parameters:
#   - None
# Return:
#   - None
# Note:
#   - Creates global temporary file 'err' for redirecting error messages.
function trap_error() {
  declare -g err
  err=$(mktemp)
  
  trap 'rm $err' EXIT
  trap '_err_handler "$err" "$BASH_COMMAND" "$?"' ERR
}

# Function: check_status
# Purpose:
#   - Log an error message and terminate the script or function with an exit
#   status of 1 if the return value is non-zero.
# Parameters:
#   - return_value: The return value to check.
# Return:
#   - 0 if the return value is zero, otherwise the function or shell is
#   terminated with an exit status of 1.
function check_status() {
  function _usage() {
    printf "%s\n" "Usage: ${FUNCNAME[1]} [INTEGER]" >&2
  }
  
  local return_value="$1"
  
  if [[ -z "$return_value" ]]; then
    _missing_operand
    _usage
    exit 1
  fi
  
  if ! [[ "$return_value" =~ ^[0-9]+$ ]]; then
    _invalid_option "$1"
    _usage
    exit 1
  fi

  if [[ $return_value -ne 0 ]]; then
    log --verbose --critical "Exited with non-zero return value: $return_value"
    exit 1
  fi
  
  return 0
}
