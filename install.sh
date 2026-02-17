#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Bootstrap: Install chezmoi + all dev tools (idempotent)
#
# Workflow:
#   First machine:  ./install.sh
#                   chezmoi init --apply  (uses local chezmoi-dotfiles/)
#                   chezmoi cd && git remote add origin ... && git push
#
#   New machine:    curl -fsLS get.chezmoi.io | sh
#                   chezmoi init --apply $GITHUB_USERNAME
#                   (chezmoi run_once scripts handle tool installation)
# =============================================================================

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info() { echo -e "${GREEN}[✓]${NC} $*"; }
warn() { echo -e "${YELLOW}[→]${NC} $*"; }

OS="unknown"
[[ "$OSTYPE" == "darwin"* ]] && OS="macos"
[[ -f /etc/debian_version ]]  && OS="debian"
[[ "$OS" == "unknown" ]] && { echo "Unsupported OS"; exit 1; }
info "Detected: $OS ($(uname -m))"

# --- Package manager ---
if [[ "$OS" == "macos" ]]; then
    command -v brew &>/dev/null || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    P="brew install"
else
    sudo apt-get update -qq
    P="sudo apt-get install -y -qq"
fi

inst() { command -v "$1" &>/dev/null && info "$1 ✓" || { warn "Installing $1..."; $P "${@:2}"; }; }

# --- 1. chezmoi ---
if command -v chezmoi &>/dev/null; then
    info "chezmoi ✓"
else
    warn "Installing chezmoi..."
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
    export PATH="$HOME/.local/bin:$PATH"
    info "chezmoi installed"
fi

# --- 2. Core tools ---
inst tmux tmux
inst git git
inst curl curl
inst unzip unzip
inst rg ripgrep
inst fzf fzf
if [[ "$OS" == "debian" ]]; then
    inst fdfind fd-find
    command -v fd &>/dev/null || sudo ln -sf "$(command -v fdfind)" /usr/local/bin/fd
else
    inst fd fd
fi

# --- 3. Neovim ---
if command -v nvim &>/dev/null; then
    info "nvim ✓ ($(nvim --version | head -1))"
else
    warn "Installing Neovim..."
    if [[ "$OS" == "macos" ]]; then brew install neovim
    else
        curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
        sudo rm -rf /opt/nvim && sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
        sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
        rm -f nvim-linux-x86_64.tar.gz
    fi
fi

# --- 4. lazygit ---
if command -v lazygit &>/dev/null; then info "lazygit ✓"
else
    warn "Installing lazygit..."
    if [[ "$OS" == "macos" ]]; then brew install lazygit
    else
        LG_VER=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
        curl -Lo /tmp/lg.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LG_VER}_Linux_x86_64.tar.gz"
        tar xf /tmp/lg.tar.gz -C /tmp lazygit && sudo install /tmp/lazygit /usr/local/bin && rm -f /tmp/lg.tar.gz /tmp/lazygit
    fi
fi

# --- 5. Go ---
if command -v go &>/dev/null; then info "go ✓ ($(go version))"
else
    warn "Installing Go..."
    if [[ "$OS" == "macos" ]]; then brew install go
    else
        GO_VER=$(curl -s https://go.dev/VERSION?m=text | head -1)
        curl -LO "https://go.dev/dl/${GO_VER}.linux-amd64.tar.gz"
        sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf "${GO_VER}.linux-amd64.tar.gz"
        rm -f "${GO_VER}.linux-amd64.tar.gz"
    fi
fi
export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin"

# --- 6. Go tools ---
for tool in \
    "golang.org/x/tools/gopls@latest" \
    "github.com/golangci/golangci-lint/cmd/golangci-lint@latest" \
    "github.com/go-delve/delve/cmd/dlv@latest" \
    "golang.org/x/tools/cmd/goimports@latest" \
    "github.com/fatih/gomodifytags@latest" \
    "github.com/josharian/impl@latest" \
    "github.com/cweill/gotests/gotests@latest"
do
    name=$(basename "${tool%%@*}")
    command -v "$name" &>/dev/null && info "go:$name ✓" || { warn "go install $name..."; go install "$tool"; }
done

# --- 7. Node.js + Claude Code ---
if command -v node &>/dev/null; then info "node ✓ ($(node --version))"
else
    warn "Installing Node.js..."
    if [[ "$OS" == "macos" ]]; then brew install node
    else curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - && sudo apt-get install -y nodejs
    fi
fi

command -v claude &>/dev/null && info "claude ✓" || { warn "Installing Claude Code..."; npm install -g @anthropic-ai/claude-code; }

# --- 8. Nerd Font (JetBrains Mono — best for coding) ---
if [[ "$OS" == "macos" ]]; then
    if brew list --cask font-jetbrains-mono-nerd-font &>/dev/null 2>&1; then
        info "JetBrains Mono Nerd Font ✓"
    else
        warn "Installing JetBrains Mono Nerd Font..."
        brew install --cask font-jetbrains-mono-nerd-font
        info "JetBrains Mono Nerd Font installed"
        echo -e "${YELLOW}  → Set your terminal font to 'JetBrainsMono Nerd Font' in Preferences${NC}"
    fi
else
    FONT_DIR="$HOME/.local/share/fonts"
    if ls "$FONT_DIR"/JetBrainsMono*.ttf &>/dev/null 2>&1; then
        info "JetBrains Mono Nerd Font ✓"
    else
        warn "Installing JetBrains Mono Nerd Font..."
        mkdir -p "$FONT_DIR"
        curl -fLo /tmp/JetBrainsMono.tar.xz "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz"
        tar -xf /tmp/JetBrainsMono.tar.xz -C "$FONT_DIR"
        fc-cache -fv "$FONT_DIR" >/dev/null 2>&1
        rm -f /tmp/JetBrainsMono.tar.xz
        info "JetBrains Mono Nerd Font installed"
    fi
fi

# --- 9. delta (better diffs) ---
if command -v delta &>/dev/null; then info "delta ✓"
else
    warn "Installing delta..."
    if [[ "$OS" == "macos" ]]; then brew install git-delta
    else
        D_VER=$(curl -s "https://api.github.com/repos/dandavison/delta/releases/latest" | grep -Po '"tag_name": "\K[^"]*')
        curl -Lo /tmp/delta.deb "https://github.com/dandavison/delta/releases/latest/download/git-delta_${D_VER}_amd64.deb"
        sudo dpkg -i /tmp/delta.deb || sudo apt-get -f install -y; rm -f /tmp/delta.deb
    fi
fi

# --- 10. Secret leakage protection (pre-commit + gitleaks + age) ---
inst age age
if command -v gitleaks &>/dev/null; then info "gitleaks ✓"
else
    warn "Installing gitleaks..."
    if [[ "$OS" == "macos" ]]; then brew install gitleaks
    else
        GL_VER=$(curl -s "https://api.github.com/repos/gitleaks/gitleaks/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
        curl -Lo /tmp/gitleaks.tar.gz "https://github.com/gitleaks/gitleaks/releases/latest/download/gitleaks_${GL_VER}_linux_x64.tar.gz"
        tar xf /tmp/gitleaks.tar.gz -C /tmp gitleaks && sudo install /tmp/gitleaks /usr/local/bin && rm -f /tmp/gitleaks.tar.gz /tmp/gitleaks
    fi
fi

if command -v pre-commit &>/dev/null; then info "pre-commit ✓"
else
    warn "Installing pre-commit..."
    if [[ "$OS" == "macos" ]]; then brew install pre-commit
    else pip3 install pre-commit
    fi
fi

# Activate pre-commit hooks in this repo
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/.pre-commit-config.yaml" ]]; then
    (cd "$SCRIPT_DIR" && pre-commit install) && info "pre-commit hooks ✓"
fi

# --- 11. TPM ---
TPM="$HOME/.tmux/plugins/tpm"
[[ -d "$TPM" ]] && info "TPM ✓" || { warn "Installing TPM..."; git clone https://github.com/tmux-plugins/tpm "$TPM"; }

# --- 12. LazyVim starter ---
NV="$HOME/.config/nvim"
if [[ -f "$NV/lazyvim.json" ]] || [[ -f "$NV/lua/config/lazy.lua" ]]; then
    info "LazyVim ✓"
else
    [[ -d "$NV" ]] && mv "$NV" "$NV.bak.$(date +%s)"
    warn "Cloning LazyVim starter..."
    git clone https://github.com/LazyVim/starter "$NV" && rm -rf "$NV/.git"
fi

# --- PATH ---
RC="$HOME/.bashrc"; [[ "$SHELL" == *zsh ]] && RC="$HOME/.zshrc"
for line in \
    'export PATH="$HOME/.local/bin:$PATH:/usr/local/go/bin:$HOME/go/bin:$HOME/bin"' \
    'export EDITOR="nvim"' \
    'export VISUAL="nvim"'
do grep -qF "$line" "$RC" 2>/dev/null || echo "$line" >> "$RC"; done

echo ""
echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Tools installed! Now deploy dotfiles with chezmoi:${NC}"
echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
echo ""
echo "  FIRST TIME:   chezmoi init"
echo "                cp -r chezmoi-dotfiles/* \$(chezmoi source-path)/"
echo "                chezmoi apply -v"
echo "                chezmoi cd && git remote add origin ... && git push"
echo ""
echo "  NEW MACHINE:  chezmoi init --apply \$GITHUB_USERNAME"
echo ""
echo -e "  ${YELLOW}IMPORTANT:${NC} Set terminal font to 'JetBrainsMono Nerd Font'"
echo "             (Terminal/iTerm2 → Preferences → Profiles → Font)"
echo ""
