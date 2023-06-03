#!/bin/bash

run_tests_in_directory() {
  local directory="$1"
  
  local tests
  tests=$(find "$directory" -name "test_*" -type f)

  if [[ -n "$tests" ]]; then
    for test_file in $tests; do
      printf "Running test: %s\n" "$test_file"
      bash "$test_file"
    done
  fi
}

run_tests_recursive() {
  local base_directory="$1"
  local test_directory="$base_directory/unit"
  local sub_directories

  if [[ -d "$test_directory" ]]; then
    sub_directories=$(find "$test_directory" -type d)
    for sub_directory in $sub_directories; do
      run_tests_in_directory "$sub_directory"
    done
  else
    printf "Test directory not found: %s\n" "$test_directory"
    exit 1
  fi
}

main() {
  local base_directory
  base_directory=$(dirname "$0")
  run_tests_recursive "$base_directory"
}

main
