# CLAUDE.md - Repository Guide for Claude Code

## Repository Purpose

This is a **dotfiles management repository** using [chezmoi](https://www.chezmoi.io/) to synchronize and manage configuration files across multiple machines.

**Target Environment**: WSL2 (Windows Subsystem for Linux)

## Directory Structure

```
.
├── .chezmoi.toml.tmpl          # Chezmoi config template (git name, email, Windows username)
├── .chezmoiignore              # Files to ignore (README.md)
├── dot_gitconfig.tmpl          # Git config template
├── dot_zshrc.tmpl              # Zsh config template (main shell configuration)
├── dot_zprofile                # Zsh profile
├── dot_p10k.zsh                # Powerlevel10k theme configuration
├── mise.toml                   # mise tool version manager config
└── dot_config/
    └── sheldon/
        └── plugins.toml        # Sheldon zsh plugin manager config
```

## File Naming Convention

chezmoi uses special prefixes:
- `dot_` → `.` (creates dotfiles)
- `.tmpl` suffix → Template file (variables substituted on apply)

**Examples:**
- `dot_gitconfig.tmpl` → `~/.gitconfig`
- `dot_zshrc.tmpl` → `~/.zshrc`
- `dot_config/sheldon/plugins.toml` → `~/.config/sheldon/plugins.toml`

## Template Variables

Defined in `.chezmoi.toml.tmpl`, prompted on first init:

- `{{ .git_name }}` - Git user name
- `{{ .git_email }}` - Git email address
- `{{ .windows_username }}` - Windows username (for WSL2 path integration)

## Core Tools

### Package Managers & Version Managers
- **chezmoi**: Dotfiles management
- **mise**: Development tool version manager (`mise.toml`)
- **sheldon**: Zsh plugin manager (`dot_config/sheldon/plugins.toml`)
- **brew**: Package manager (Linuxbrew)

### Managed Tools (via mise)
- `eza`: Modern ls replacement (latest)
- `fzf`: Fuzzy finder (latest)

### Zsh Plugins (via sheldon)
- `powerlevel10k`: Theme
- `zsh-autosuggestions`: Command suggestions
- `zsh-syntax-highlighting`: Syntax highlighting
- `zsh-completions`: Enhanced completions
- `zsh-z`: Directory jumping
- `zsh-abbr`: Abbreviation expansion
- `zsh-defer`: Lazy loading plugin

## Key Features in dot_zshrc.tmpl

### Environment Variables
- `GIT_NAME`, `GIT_EMAIL`, `WINDOWS_USERNAME`: Template variables exported
- `PATH`: Includes VS Code bin for WSL2 integration
- `BROWSER`: Microsoft Edge on Windows

### Custom Functions
Located at lines 105-161:

- `gs()` - Interactive git switch with fzf (line 106-111)
- `gl()` - Interactive git log viewer with fzf (line 113-122)
- `gir()` - Interactive git rebase with fzf (line 124-129)
- `gf()` - Fetch and switch remote branch with fzf (line 131-134)
- `gb()` - Create branch with shortcuts (f/ → feature/, r/ → release/) (line 136-161)

### Aliases & Abbreviations
- `dc` → `docker compose` (abbr, line 35)
- `mr` → `mise run` (abbr, line 36)
- `ls` → `eza -F -h -@ -m --icons --git --time-style=long-iso --color=automatic --group-directories-first` (line 37)
- `ll` → Long format with all files (line 38)

### Key Bindings
- `^f` (Ctrl+F) → `fzf-z-search` - Interactive z directory search (line 101)

## WSL2 Integration

- VS Code path: `/mnt/c/Users/{{ .windows_username }}/AppData/Local/Programs/Microsoft VS Code/bin`
- Browser: `/mnt/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe`

## Common Operations

### Apply Changes
```bash
chezmoi apply           # Apply all changes
chezmoi diff            # Preview changes
```

### Edit Configuration
```bash
chezmoi cd              # Navigate to source directory
chezmoi edit ~/.zshrc   # Edit with $EDITOR
```

### Add New Files
```bash
chezmoi add ~/.newfile  # Track new dotfile
```

## Important Notes for Claude Code

1. **Always edit template files** (`.tmpl`) for files that need template variables
2. **File naming**: Use `dot_` prefix for dotfiles in chezmoi source
3. **Testing changes**: Use `chezmoi diff` before applying
4. **WSL2 context**: This setup assumes WSL2 environment with Windows integration
5. **Git integration**: Custom git functions heavily rely on fzf for interactive selection
6. **Plugin loading**: Sheldon manages all zsh plugins; don't add manual plugin loading to .zshrc

## Quick Reference

- Main shell config: `dot_zshrc.tmpl` (162 lines)
- Git config: `dot_gitconfig.tmpl`
- Plugin config: `dot_config/sheldon/plugins.toml`
- Tool versions: `mise.toml`
- Template variables: `.chezmoi.toml.tmpl`
