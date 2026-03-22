#!/bin/bash

DOTDIR="$HOME/MacDotfiles"
DOTDOT="$DOTDIR/dotfiles"

is_font_installed() {
  local font_name="$1"
  local font_dirs=(
    "$HOME/Library/Fonts"
    "/Library/Fonts"
    "/System/Library/Fonts"
    "/System/Library/AssetsV2/com_apple_MobileAsset_Font*"
  )

  local font_dir
  for font_dir in "${font_dirs[@]}"; do
    if find "$font_dir" -type f -iname "$font_name" -print -quit 2>/dev/null | grep -q .; then
      return 0
    fi
  done

  return 1
}

install_fonts() {
  local source_dir="$DOTDIR/assets/fonts"
  local target_dir="$HOME/Library/Fonts"
  local installed_count=0
  local skipped_count=0

  if [ ! -d "$source_dir" ]; then
    echo "No font assets directory found at $source_dir."
    return
  fi

  mkdir -p "$target_dir"

  while IFS= read -r -d '' font_path; do
    local font_name
    font_name="$(basename "$font_path")"

    if is_font_installed "$font_name"; then
      echo "Skipping installed font: $font_name"
      skipped_count=$((skipped_count + 1))
      continue
    fi

    echo "Installing font: $font_name"
    cp "$font_path" "$target_dir/" || {
      echo "Failed to install font: $font_name"
      exit 1
    }
    installed_count=$((installed_count + 1))
  done < <(find "$source_dir" -type f \( -iname '*.ttf' -o -iname '*.otf' -o -iname '*.ttc' -o -iname '*.otc' -o -iname '*.dfont' \) -print0)

  echo "Font installation complete: installed $installed_count, skipped $skipped_count."
}

install_homebrew() {
  if ! command -v brew &>/dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    echo >> /Users/marcogomez/.zprofile
    echo 'eval "$(/opt/homebrew/bin/brew shellenv zsh)"' >> /Users/marcogomez/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv zsh)"
  else
    echo "Homebrew is already installed... updating..."
    brew update
  fi
}

install_rust() {
  if ! command -v rustc &>/dev/null; then
    echo "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    source "$HOME/.cargo/env"
  else
    echo "Rust is already installed... updating..."
    rustup update
  fi
}

install_oh_my_zsh() {
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  else
    echo "Oh My Zsh is already installed."
  fi
}

install_powerlevel10k() {
  local theme_dir="$HOME/.oh-my-zsh/custom/themes/powerlevel10k"

  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Skipping Powerlevel10k installation because Oh My Zsh is not installed."
    return
  fi

  mkdir -p "$HOME/.oh-my-zsh/custom/themes"

  if [ ! -d "$theme_dir" ]; then
    echo "Installing Powerlevel10k..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$theme_dir" || {
      echo "Failed to install Powerlevel10k"
      exit 1
    }
  else
    echo "Powerlevel10k is already installed... updating..."
    git -C "$theme_dir" pull --ff-only || {
      echo "Failed to update Powerlevel10k"
      exit 1
    }
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
  mkdir -p "$(dirname "$destination")"
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

install_recipes() {
  local recipe_dir
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  recipe_dir="${script_dir}/z_setup_scripts"

  local recipes=(
    "$recipe_dir/install_emscripten.sh"
  )

  for recipe in "${recipes[@]}"; do
    if [ -f "$recipe" ]; then
      echo "Running recipe: $(basename "$recipe")"
      # shellcheck source=/dev/null
      source "$recipe" || {
        echo "Failed to execute recipe: $(basename "$recipe")" >&2
        exit 1
      }
    else
      echo "Recipe not found: $(basename "$recipe")" >&2
    fi
  done
}

install_homebrew
install_homebrew_packages
install_fonts
fix_dock
fix_key_repeat
link_dotfiles
config_nginx
install_urblind
install_rust
install_oh_my_zsh
install_powerlevel10k
install_recipes
