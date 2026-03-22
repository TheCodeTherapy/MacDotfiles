#!/bin/bash

COLOR_RED=$'\033[0;31m'
COLOR_GREEN=$'\033[0;32m'
COLOR_BLUE=$'\033[0;34m'
COLOR_PURPLE=$'\033[0;35m'
COLOR_CYAN=$'\033[0;36m'
COLOR_WHITE=$'\033[0;37m'
COLOR_YELLOW=$'\033[0;33m'
COLOR_BOLD=$'\033[1m'
COLOR_OFF=$'\033[0m'

print_message() {
  local color="$1"
  local message="$2"
  local color_code="$COLOR_OFF"

  case "$color" in
    RED) color_code="$COLOR_RED" ;;
    GREEN) color_code="$COLOR_GREEN" ;;
    BLUE) color_code="$COLOR_BLUE" ;;
    PURPLE) color_code="$COLOR_PURPLE" ;;
    CYAN) color_code="$COLOR_CYAN" ;;
    WHITE) color_code="$COLOR_WHITE" ;;
    YELLOW) color_code="$COLOR_YELLOW" ;;
    BOLD) color_code="$COLOR_BOLD" ;;
  esac

  printf '%b\n' "${color_code}${message}${COLOR_OFF}"
}

print_error() {
  print_message "RED" "ERROR: $1"
}

print_warning() {
  print_message "YELLOW" "WARNING: $1"
}

print_info() {
  print_message "CYAN" "INFO: $1"
}

print_success() {
  print_message "GREEN" "SUCCESS: $1"
}

handle_error() {
  print_error "$1"
  exit 1
}

link_file() {
  local source="$1"
  local destination="$2"
  print_info "Linking $source to $destination ..."
  sudo rm -rf "$destination" >/dev/null 2>&1
  if ! ln -s "$source" "$destination"; then
    handle_error "Failed to link $source to $destination"
  fi
}
