# dotfiles

## chezmoi usage

```sh
# init
chezmoi init

# edit
chezmoi cd
cursor .
chezmoi diff

# apply
chezmoi apply
```

## brew install

```sh
brew install chezmoi
brew install mise
```

sheldon などのツールは `dot_config/mise/config.toml` でバージョン固定し、`mise install` で入れる。

## test

Ubuntu 24.04 コンテナにゼロから適用し、[goss](https://github.com/goss-org/goss) で検証する（要 Docker）。
`tests/` は `.chezmoiignore` で適用対象外。

```sh
tests/run.sh           # ビルド → chezmoi適用 → mise install → 検証
tests/run.sh --shell   # 検証後にコンテナ内のzshに入って確認
```

- 検証項目: `tests/goss.yaml`
- GitHub APIのレート制限に当たる場合は `GITHUB_TOKEN` を設定して実行
- WSL2固有のパス（`/mnt/c/...`）の実体は検証対象外