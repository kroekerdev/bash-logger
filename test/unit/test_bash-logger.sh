#!/bin/bash
      
function pass() {
  printf "\e[32m[PASS]\e[0m "
}

function fail() {
  printf "\e[31m[FAIL]\e[0m "
}

function return_test() {
  printf "%s%s\n" "${FUNCNAME[1]}" "$1"
}

function test_log() {
  local message
  local std_err
  local error_trace
  local log_msg

  for log_level in "${!LOG_LEVELS[@]}"; do
    message="${log_level,,} message"
    std_err=$(log "$log_level" "$message" 2>&1)
    error_trace="${BASH_SOURCE[0]}:${FUNCNAME[0]}:$((LINENO - 1))"
    log_msg=$(tail -n 1 "$LOG_FILE")
    IFS=' ' read -r std_err_level std_err_trace std_err_msg <<< "$std_err"
    IFS=' ' read -r date time level owner trace msg <<< "$log_msg"  

    if [[ "$std_err_level" =~ $log_level && \
      "$std_err_trace" == "[$error_trace]" && \
      "$std_err_msg" == "[$message]" && \
      "$date" =~ ^\[[0-9]{4}-[0-9]{2}-[0-9]{2}$ && \
      "$time" =~ ^[0-9]{2}:[0-9]{2}:[0-9]{2}\]$ && \
      "$level" == "[$log_level]" && \
      "$owner" == "[$(id -un):$(id -gn)]" && \
      "$trace" == "[$error_trace]" && \
      "$msg" == "[$message]" ]]; then
      pass
    else
      fail
    fi

  return_test ":$std_err:$log_msg"
  done
}

function test_log_brief() {
  local message
  local std_err

  for log_level in "${!LOG_LEVELS[@]}"; do
    message="${log_level,,} message"
    std_err=$(log --brief "$log_level" "$message" 2>&1)
    IFS=' ' read -r level msg <<< "$std_err"

    if [[ "$level" =~ $log_level && \
      "$msg" == "$message" ]]; then
      pass
    else
      fail
    fi

  return_test ":$std_err"
  done
}

function test_log_verbose() {
  local message
  local std_err
  local error_trace
  
  for log_level in "${!LOG_LEVELS[@]}"; do
    message="${log_level,,} message"
    std_err=$(log --verbose "$log_level" "$message" 2>&1)
    error_trace="${BASH_SOURCE[0]}:${FUNCNAME[0]}:$((LINENO - 1))"
    IFS=' ' read -r level trace msg <<< "$std_err"

    if [[ "$level" =~ $log_level && \
      "$trace" == "[$error_trace]" && \
      "$msg" == "[$message]" ]]; then
      pass
    else
      fail
    fi

    return_test ":$std_err"
  done
}

function test_log_suppress() {
  local message
  local std_err

  for log_level in "${!LOG_LEVELS[@]}"; do
    message="${log_level,,} message"
    std_err=$(log --suppress "$log_level" "$message" 2>&1)
    
    if [[ -z "$std_err" ]]; then
      pass
    else
      fail
    fi

    return_test ":$log_level"
  done
}

function test_log_no-suppress() {
  local message
  local std_err

  SUPPRESS_CONSOLE=TRUE

  for log_level in "${!LOG_LEVELS[@]}"; do
    message="${log_level,,} message"
    std_err=$(log --no-suppress "$log_level" "$message" 2>&1)
    
    if [[ -n "$std_err" ]]; then
      pass
    else
      fail
    fi

    return_test ":$std_err"
  done
}

function test_log_file() {
  local message
  local msg_file
  local error_trace
  local log_msg
  
  msg_file="$(mktemp)"
  
  for log_level in "${!LOG_LEVELS[@]}"; do
    message="${log_level,,} message read from file"
    printf "%s\n" "$message" > "$msg_file"
    log  "$log_level" --file "$msg_file" 2>/dev/null
    error_trace="${BASH_SOURCE[0]}:${FUNCNAME[0]}:$((LINENO - 1))"
    log_msg=$(tail -n 1 "$LOG_FILE")
    IFS=' ' read -r date time level owner trace msg <<< "$log_msg"  
    
    if [[ "$level" == "[$log_level]" && \
      "$date" =~ ^\[[0-9]{4}-[0-9]{2}-[0-9]{2}$ && \
      "$time" =~ ^[0-9]{2}:[0-9]{2}:[0-9]{2}\]$ && \
      "$owner" == "[$(id -un):$(id -gn)]" && \
      "$trace" == "[$error_trace]" && \
      "$msg" == "[$message]" ]]; then
      pass
    else
      fail
    fi

    return_test ":$log_msg"
  done

  rm "$msg_file"
}

function test_set_log_level() {
  for level in "${!LOG_LEVELS[@]}"; do
    set_log_level "$level"

    if [[ "$level" == "$LOG_LEVEL"  ]]; then
      pass
    else
      fail
    fi

    return_test ":$level"
  done
}

function test_set_log_level_export() {
  for level in "${!LOG_LEVELS[@]}"; do
    set_log_level --export "$level"

    if [[ "$level" == "$(printenv 'LOG_LEVEL')" ]]; then
      pass
    else
      fail
    fi

    return_test ":$level"
  done
}

function test_set_log_formatter() {
  local -a log_formatters=('BRIEF' 'VERBOSE')

  for formatter in "${log_formatters[@]}"; do
    set_log_formatter "$formatter"

    if [[ "$formatter" == "$LOG_FORMATTER" ]]; then
      pass
    else
      fail
    fi

    return_test ":$formatter"
  done
}

function test_set_log_formatter_export() {
  local -a log_formatters=('BRIEF' 'VERBOSE')

  for formatter in "${log_formatters[@]}"; do
    set_log_formatter --export "$formatter"
    
    if [[ "$formatter" == "$(printenv 'LOG_FORMATTER')" ]]; then
      pass
    else
      fail
    fi

    return_test ":$formatter"
  done
}

function test_set_log_file() {
  local log_file
  log_file=$(mktemp -p "$(mktemp -d)")
  
  set_log_file "$log_file"
  
  if [[ $(stat -c "%a" "$log_file") -eq 600 ]]; then
    pass
  else
    fail
  fi

  return_test
  rm -rf "$(dirname "$log_file")"
}

function test_set_log_file_export() {
  local log_file
  log_file=$(mktemp -p "$(mktemp -d)")
  
  set_log_file --export "$log_file"
  
  if [[ $(stat -c "%a" "$log_file") -eq 600 && \
    "$log_file" == "$(printenv 'LOG_FILE')" ]]; then
    pass
  else
    fail
  fi

  return_test
  rm -rf "$(dirname "$log_file")"
}

function test_set_suppress_console() {
  local -a boolean=('TRUE' 'FALSE')
  
  for bool in "${boolean[@]}"; do
    set_suppress_console "$bool"
    
    if [[ "$bool" == "$SUPPRESS_CONSOLE" ]]; then
      pass
    else
      fail
    fi

    return_test ":$bool"
 done
}

function test_set_suppress_console_export() {
  local -a boolean=('TRUE' 'FALSE')
  
  for bool in "${boolean[@]}"; do
    set_suppress_console --export "$bool"
    
    if [[ "$bool" == "$(printenv 'SUPPRESS_CONSOLE')" ]]; then
      pass
    else
      fail
    fi

    return_test ":$bool"
  done
}

function test_trap_error() {
  local -i return_value
  local command='null_command'
  local error_trace
  local log_msg

  (
    trap_error
    eval "$command 2>$err"
  ) 2>/dev/null
  return_value=$?
  error_trace="${BASH_SOURCE[0]}:${FUNCNAME[0]}:$((LINENO - 3))"

  log_msg=$(tail -n 1 "$LOG_FILE")
  IFS=' ' read -r date time level owner trace last_command msg <<< "$log_msg"  

  if [[ $return_value -eq 1 && \
    "$date" =~ ^\[[0-9]{4}-[0-9]{2}-[0-9]{2}$ && \
    "$time" =~ ^[0-9]{2}:[0-9]{2}:[0-9]{2}\]$ && \
    "$level" == "[ERROR]" && \
    "$owner" == "[$(id -un):$(id -gn)]" && \
    "$trace" == "[$error_trace]" && \
    "[$command:127]" == "$last_command" && \
    -n "$msg" ]]; then
    pass
  else
    fail
  fi

  return_test ":$log_msg"
}

function test_check_status() {
  if { ! ( check_status 1 ) 2>/dev/null; }; then
    pass
  else
    fail
  fi

  return_test
}

function main() {
  source ../src/bash-logger.sh

  LOG_LEVEL='DEBUG'
  LOG_FILE="$(mktemp)"

  test_log
  test_log_brief
  test_log_verbose
  test_log_suppress
  test_log_no-suppress
  test_log_file

  test_trap_error
  test_check_status

  rm "$LOG_FILE"
  unset LOG_FILE
  unset LOG_LEVEL

  test_set_log_level
  test_set_log_level_export
  test_set_log_formatter
  test_set_log_formatter_export
  test_set_log_file
  test_set_log_file_export
  test_set_suppress_console
  test_set_suppress_console_export
}

main
