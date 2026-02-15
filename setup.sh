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
  ghostty_config_dir="$HOME/Library/Application Support/com.mitchellh.ghostty"
  hammerspoon_config_dir="$HOME/.hammerspoon"
  global_config_dir="$HOME/.config"

  mkdir -p "$vscode_config_dir"
  mkdir -p "$cursor_config_dir"
  mkdir -p "$ghostty_config_dir"

  dot_config_dir="$HOME/.config"

  files_to_link=(
    "$DOTDOT/vscode/settings.json" "$vscode_config_dir/settings.json"
    "$DOTDOT/cursor/settings.json" "$cursor_config_dir/settings.json"
    "$DOTDOT/nvim" "$dot_config_dir/nvim"
    "$DOTDOT/alacritty/alacritty.toml" "$dot_config_dir/alacritty/alacritty.toml"
    "$DOTDOT/ghostty/config" "$ghostty_config_dir/config"
    "$DOTDOT/ghostty/shaders" "$ghostty_config_dir/shaders"
    "$DOTDOT/ghostty/themes" "$ghostty_config_dir/themes"
    "$DOTDOT/profile/profile" "$HOME/.profile"
    "$DOTDOT/zsh/zshrc" "$HOME/.zshrc"
    "$DOTDOT/profile/zprofile" "$HOME/.zprofile"
    "$DOTDOT/keybindings/DefaultKeyBinding.dict" "$HOME/Library/KeyBindings/DefaultKeyBinding.dict"
    "$DOTDOT/hammerspoon" "$hammerspoon_config_dir"
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

config_nginx() {
  local nginx_conf="/opt/homebrew/etc/nginx/nginx.conf"
  local backup_conf="/opt/homebrew/etc/nginx/nginx.conf.backup"
  
  # Backup original if it exists and no backup yet
  if [ -f "$nginx_conf" ] && [ ! -f "$backup_conf" ]; then
    echo "Backing up original nginx.conf..."
    cp "$nginx_conf" "$backup_conf"
  fi
  
  echo "Installing custom nginx config..."
  cp "$DOTDOT/nginx/nginx.conf" "$nginx_conf"
  
  # Reload nginx if it's running
  if pgrep nginx >/dev/null; then
    echo "Reloading nginx..."
    brew services restart nginx
  fi
}

install_urblind() {
  if [[ -f "$DOTDIR/bin/urblind" ]]; then
    rm "$DOTDIR/bin/urblind" || {
      echo "Failed to remove existing urblind binary"
      exit 1
    }
  fi
  echo "Building urblind..."
  cd "$DOTDIR/tools/urblind" || {
    echo "Failed to change directory to $DOTDIR/tools/urblind"
    exit 1
  }
  ./build_posix.sh || {
    echo "Failed to build urblind"
    exit 1
  }

  cp "./build/urblind" "$DOTDIR/bin/" || {
    echo "Failed to copy urblind to bin/"
    exit 1
  }

  cd "$DOTDIR" || {
    echo "Failed to change directory back to $DOTDIR"
    exit 1
  }
}

install_homebrew
install_homebrew_packages
fix_dock
fix_key_repeat
link_dotfiles
config_nginx
install_urblind
