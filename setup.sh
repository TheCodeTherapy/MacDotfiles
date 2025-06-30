#!/bin/bash

DOTDIR="$HOME/MacDotfiles"
DOTDOT="$DOTDIR/dotfiles"

install_homebrew() {
  if ! command -v brew &>/dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    echo "Homebrew is already installed... updating..."
    brew update
  fi
}

install_homebrew_packages() {
  echo "Installing Homebrew packages..."
  brew bundle --file="$DOTDOT/brew/Brewfile" --no-upgrade || {
    echo "❌ Brew bundle failed"
    exit 1
  }
  if ! command -v alacritty &>/dev/null; then
    echo "Installing Alacritty..."
    brew install --cask alacritty --no-quarantine
  else
    echo "Alacritty is already installed."
  fi
}

link_file() {
  local source="$1"
  local destination="$2"
  echo "Linking $source to $destination ..."
  rm -rf "$destination" >/dev/null 2>&1
  if ! ln -s "$source" "$destination"; then
    echo "Failed to link $source to $destination" >&2
    exit 1
  fi
}

link_dotfiles() {
  vscode_config_dir="$HOME/Library/Application Support/Code/User"
  cursor_config_dir="$HOME/Library/Application Support/Cursor/User"

  mkdir -p "$vscode_config_dir"
  mkdir -p "$cursor_config_dir"

  dot_config_dir="$HOME/.config"

  files_to_link=(
    "$DOTDOT/vscode/settings.json" "$vscode_config_dir/settings.json"
    "$DOTDOT/cursor/settings.json" "$cursor_config_dir/settings.json"
    "$DOTDOT/nvim" "$dot_config_dir/nvim"
    "$DOTDOT/alacritty/alacritty.toml" "$dot_config_dir/alacritty/alacritty.toml"
    "$DOTDOT/profile/profile" "$HOME/.profile"
    "$DOTDOT/zsh/zshrc" "$HOME/.zshrc"
    "$DOTDOT/profile/zprofile" "$HOME/.zprofile"
    "$DOTDOT/keybindings/DefaultKeyBinding.dict" "$HOME/Library/KeyBindings/DefaultKeyBinding.dict"
  )

  local i=0
  while [ $i -lt ${#files_to_link[@]} ]; do
    src="${files_to_link[$i]}"
    dst="${files_to_link[$((i + 1))]}"
    link_file "$src" "$dst"
    i=$((i + 2))
  done
}

fix_dock() {
  # To make the Dock instantly leap back into view when it's needed, rather than slide:
  # defaults write com.apple.dock autohide-time-modifier -int 0; killall Dock

  # To make the animation for the dock to reappear to last for 0.15s:
  defaults write com.apple.dock autohide-time-modifier -float 0.21
  killall Dock

  # To revert back to the default sliding effect:
  # defaults delete com.apple.dock autohide-time-modifier; killall Dock
}

fix_key_repeat() {
  # Set the key repeat rate to fast
  defaults write NSGlobalDomain KeyRepeat -int 1
  # Set the delay until repeat to short
  defaults write NSGlobalDomain InitialKeyRepeat -int 20
}

install_homebrew
install_homebrew_packages
fix_dock
fix_key_repeat
link_dotfiles
