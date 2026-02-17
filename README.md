# Dev Setup: chezmoi + tmux + nvim + lazygit + Claude Code

A complete, idempotent Go development environment managed by [chezmoi](https://chezmoi.io).

## Architecture

```
chezmoi manages all dotfiles
├── ~/.tmux.conf          ← tmux (prefix Ctrl-a, resurrect, vim-tmux-navigator)
├── ~/.gitconfig          ← git (delta, sensible defaults)
├── ~/.config/
│   ├── nvim/lua/         ← LazyVim + Go extras (gopls, neotest, gopher.nvim)
│   └── lazygit/config.yml ← lazygit (Go test/lint commands, conventional commits)
└── ~/bin/dev             ← tmux session starter (replaces tmuxinator)
```

## Quick Start

### First Machine (you have the configs)

```bash
# 1. Install all tools
chmod +x install.sh && ./install.sh

# 2. Initialize chezmoi and copy configs
chezmoi init
cp -r chezmoi-dotfiles/* "$(chezmoi source-path)/"
chezmoi diff     # review changes
chezmoi apply -v # deploy to home directory

# 3. Push to GitHub
chezmoi cd
git remote add origin git@github.com:YOUR_USERNAME/dotfiles.git
git add . && git commit -m "feat: initial dotfiles" && git push -u origin main
exit
```

### New Machine (bootstrap from GitHub)

```bash
# Single command: installs chezmoi + pulls dotfiles + runs install script
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply YOUR_GITHUB_USERNAME
```

The `run_once_install-tools.sh` script inside chezmoi automatically installs
all tools (tmux, nvim, lazygit, Go, Claude Code, delta, JetBrains Mono Nerd Font,
age, gitleaks, pre-commit, etc.) on first apply.

> **After install:** Set your terminal font to **JetBrainsMono Nerd Font** in
> Terminal.app → Preferences → Profiles → Font, or iTerm2 → Preferences →
> Profiles → Text → Font. This enables icons in nvim, lazygit, and the tmux
> status bar.

## Why Not tmuxinator?

**tmuxinator is no longer best practice** for this workflow:

| | tmuxinator | tmux-resurrect + `dev` script |
|---|---|---|
| Dependencies | Ruby + gem | bash only |
| Config files | YAML per project (must maintain) | Zero config (auto-saves state) |
| Layout changes | Must update YAML | Automatic |
| Session persistence | None (recreates each time) | Survives reboots |
| Startup | `mux start project` | `dev project` |

Our setup uses **tmux-resurrect + tmux-continuum** (auto-saves every 15 min,
auto-restores on tmux start) combined with a simple `~/bin/dev` script for
project-specific layouts. Zero Ruby, zero YAML.

## Why chezmoi?

- **Written in Go** — single binary, no runtime deps
- **Templates** — one config adapts to macOS/Linux (clipboard, paths)
- **Secrets** — encrypts sensitive files with `age` (see below)
- **run_once scripts** — tool installation happens on `chezmoi apply`
- **One-liner bootstrap** — new machine → single curl command

## Secret Management

This repo uses three layers of protection against accidentally leaking secrets:

1. **`.gitignore`** — prevents git from tracking common secret file patterns (`*.pem`, `.env`, `id_rsa*`, etc.)
2. **`.chezmoiignore`** — prevents `chezmoi add` from pulling sensitive `$HOME` files (SSH keys, GPG keyring, shell history, cloud credentials, age private key) into the source state — critical because `autoCommit = true`
3. **`gitleaks` pre-commit hook** — scans staged files for embedded secrets (API keys, tokens) before every commit

### age Encryption (for secrets that belong in the repo)

Some secrets (like `~/.ssh/config`) need to live in the repo so chezmoi can deploy them. These are encrypted with [age](https://github.com/FiloSottile/age) — chezmoi decrypts them on `chezmoi apply`.

**One-time setup:**

```bash
# Generate your age key (store it safely — losing it = losing access to encrypted secrets)
age-keygen -o ~/.config/chezmoi/key.txt

# The public key is printed by age-keygen (starts with "age1...")
# chezmoi will prompt for it on `chezmoi init`
```

**Adding encrypted files:**

```bash
# Add a file encrypted (stored with encrypted_ prefix in source state)
chezmoi add --encrypt ~/.ssh/config

# Verify it's encrypted (should NOT be plaintext)
cat "$(chezmoi source-path)/encrypted_dot_ssh/config"

# chezmoi apply decrypts automatically
chezmoi apply -v
```

**Back up your age key!** Store `~/.config/chezmoi/key.txt` somewhere safe (e.g., macOS Keychain note, printed on paper, USB drive). The key is **not** in this repo — if you lose it, you cannot decrypt your secrets.

### Pre-commit Hook Setup

The gitleaks pre-commit hook is installed automatically by `install.sh` and by the `run_once_install-tools.sh` chezmoi script on new machines. To manually set it up:

```bash
pre-commit install          # activate hooks
pre-commit run --all-files  # test on all existing files
gitleaks detect --source .  # full repo history scan
```

## Editing Configs

```bash
# Edit a managed file (opens in $EDITOR, auto-tracked by chezmoi)
chezmoi edit ~/.tmux.conf
chezmoi edit ~/.config/nvim/lua/plugins/go.lua

# See what changed
chezmoi diff

# Apply changes
chezmoi apply -v

# Push to GitHub (if autoCommit is on, just push)
chezmoi cd && git push && exit

# Pull changes on another machine
chezmoi update
```

## The `dev` Command (tmuxinator replacement)

```bash
dev                          # Start/attach "dev" session in cwd
dev myproject                # Named session "myproject"
dev myproject ~/code/myproj  # Named session in specific dir
```

Creates three windows:
1. **editor** — nvim (fullscreen)
2. **terminal** — lazygit | shell (split)
3. **claude** — Claude Code

If the session already exists, it reattaches. Combined with tmux-resurrect,
your sessions survive reboots without any config files.

## Key Bindings Cheat Sheet

### tmux (prefix = `Ctrl-a`)

| Key | Action |
|---|---|
| `Ctrl-a \|` | Split vertical |
| `Ctrl-a -` | Split horizontal |
| `Ctrl-a g` | Open lazygit |
| `Ctrl-a C` | Open Claude Code |
| `Ctrl-h/j/k/l` | Navigate panes (works across nvim!) |
| `Ctrl-a d` | Detach |
| `Ctrl-a I` | Install TPM plugins |

### nvim (LazyVim)

| Key | Action |
|---|---|
| `Space` | Leader menu (self-documenting) |
| `Space ff` | Find file |
| `Space fg` | Live grep |
| `Space e` | File explorer |
| `Space gg` | lazygit (floating) |
| `Space tc` | Claude Code terminal |
| `Space ct` | Toggle test file (foo.go ↔ foo_test.go) |
| `Space rt` | Run test under cursor |
| `Space cge` | Generate `if err != nil` |
| `Space cgt` | Add json struct tags |
| `gd` | Go to definition |
| `K` | Hover docs |

### lazygit

| Key | Action |
|---|---|
| `Space` | Stage/unstage |
| `c` | Commit |
| `P` / `p` | Push / Pull |
| `T` | Run Go tests (custom) |
| `L` | Run golangci-lint (custom) |
| `A` | Open Claude Code (custom) |
| `Ctrl-f` | Conventional commit wizard |
| `?` | Help |

## File Structure (chezmoi source state)

```
chezmoi-dotfiles/               # → push as GitHub dotfiles repo
├── .chezmoi.toml.tmpl          # prompts for name/email/github/age-key on init
├── .chezmoiignore              # excludes secrets from chezmoi source state
├── .chezmoiscripts/
│   └── run_once_install-tools.sh.tmpl  # installs all tools on first apply
├── bin/
│   └── executable_dev          # → ~/bin/dev (tmux session launcher)
├── dot_gitconfig.tmpl          # → ~/.gitconfig (uses chezmoi data)
├── dot_tmux.conf.tmpl          # → ~/.tmux.conf (adapts clipboard to OS)
└── dot_config/
    ├── lazygit/config.yml      # → ~/.config/lazygit/config.yml
    └── nvim/lua/
        ├── config/
        │   ├── keymaps.lua     # → ~/.config/nvim/lua/config/keymaps.lua
        │   └── options.lua     # → ~/.config/nvim/lua/config/options.lua
        └── plugins/
            └── go.lua          # → ~/.config/nvim/lua/plugins/go.lua
```
