#!/usr/bin/env bash
# コンテナ内で実行: chezmoi適用 → mise install → goss検証
set -euo pipefail
# WSL2のログインシェル相当（docker execのumaskは0になる場合がある）
umask 022

src="$HOME/ghq/github.com/nangashi/chezmoi"
mkdir -p "$(dirname "$src")"
cp -a /src "$src"

echo "==> chezmoi init --apply"
GIT_NAME="Test User" GIT_EMAIL="test@example.com" WINDOWS_USERNAME="tester" \
  chezmoi init --source "$src" --apply --no-tty

# 失敗しても後続の検証は続け、まとめて結果を出す
status=0
echo "==> mise install"
mise install --yes || status=$?

# 初回起動はsheldonのプラグイン取得ログが出るため、検証前に一度起動しておく
echo "==> zsh warm-up"
zsh -lic exit || status=$?

echo "==> goss validate"
goss --gossfile /src/tests/goss.yaml validate --format documentation --color || status=$?

if [[ "${1:-}" == "--shell" ]]; then
  exec zsh -l
fi
exit "$status"
