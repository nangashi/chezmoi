#!/bin/bash
set -euo pipefail

NVIM_CONFIG="$HOME/.config/nvim"

# ~/.config/nvim はchezmoi管理のファイル（lazyvim.json, lua/config/options.lua）で
# 先に作られるため、ディレクトリではなく init.lua の有無で判定する
if [ ! -f "$NVIM_CONFIG/init.lua" ]; then
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT
    git clone --depth 1 https://github.com/LazyVim/starter "$tmp/starter"
    rm -rf "$tmp/starter/.git"
    mkdir -p "$NVIM_CONFIG"
    # chezmoi管理のファイルは上書きしない
    cp -r --update=none "$tmp/starter/." "$NVIM_CONFIG/"
    echo "LazyVim installed successfully"
fi
