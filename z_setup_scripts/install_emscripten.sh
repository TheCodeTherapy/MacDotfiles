#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_helpers.sh"

EMSCRIPTENPATH="$HOME/.emsdk"
export EMSCRIPTENPATH="$EMSCRIPTENPATH"

require_command() {
  local command_name="$1"

  if ! command -v "$command_name" >/dev/null 2>&1; then
    handle_error "Required command not found: $command_name"
  fi
}

persist_emscripten_env() {
  local zprofile_path="$HOME/.zprofile"
  local emsdk_line='[ -f "$HOME/.emsdk/emsdk_env.sh" ] && . "$HOME/.emsdk/emsdk_env.sh" >/dev/null 2>&1'

  touch "$zprofile_path" || handle_error "Failed to create $zprofile_path"

  if ! grep -Fqx "$emsdk_line" "$zprofile_path"; then
    printf '\n%s\n' "$emsdk_line" >> "$zprofile_path" || handle_error "Failed to update $zprofile_path"
  fi
}

install_emscripten() {
  require_command git
  require_command python3

  if [[ -d "$EMSCRIPTENPATH" ]]; then
    print_info "Emscripten source already cloned. Updating ..."

    cd "$EMSCRIPTENPATH" || handle_error "Failed to change directory to $EMSCRIPTENPATH"

    git pull --ff-only || handle_error "Failed to pull Emscripten source"

    ./emsdk install latest || handle_error "Failed to install Emscripten"

    ./emsdk activate latest || handle_error "Failed to activate Emscripten"

    export PATH="$PATH:$EMSCRIPTENPATH"
    if [ -d "$EMSCRIPTENPATH/upstream/emscripten" ]; then
      export PATH="$PATH:$EMSCRIPTENPATH/upstream/emscripten"
    fi

    source "$EMSCRIPTENPATH/emsdk_env.sh" || handle_error "Failed to source emsdk_env.sh"
    persist_emscripten_env

    print_success "Emscripten updated successfully."
  else
    print_info "Cloning Emscripten source ..."

    cd "$HOME" || handle_error "Failed to change directory to $HOME"

    git clone https://github.com/emscripten-core/emsdk.git "$EMSCRIPTENPATH" || handle_error "Failed to clone Emscripten source"

    cd "$EMSCRIPTENPATH" || handle_error "Failed to change directory to $EMSCRIPTENPATH"

    git pull --ff-only || handle_error "Failed to pull Emscripten source"

    ./emsdk install latest || handle_error "Failed to install Emscripten"

    ./emsdk activate latest || handle_error "Failed to activate Emscripten"

    export PATH="$PATH:$EMSCRIPTENPATH"
    if [ -d "$EMSCRIPTENPATH/upstream/emscripten" ]; then
      export PATH="$PATH:$EMSCRIPTENPATH/upstream/emscripten"
    fi

    source "$EMSCRIPTENPATH/emsdk_env.sh" || handle_error "Failed to source emsdk_env.sh"
    persist_emscripten_env

    print_success "Emscripten installed successfully."
  fi
}

install_emscripten