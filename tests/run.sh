#!/usr/bin/env bash
# Ubuntuコンテナ上でdotfilesをゼロから適用し、gossで検証する
#   tests/run.sh           ビルド → 適用 → 検証
#   tests/run.sh --shell   検証後にコンテナ内のzshに入る
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
image=chezmoi-test

# shellcheck disable=SC2086
docker build ${DOCKER_BUILD_OPTS:-} \
  ${BASE_IMAGE:+--build-arg BASE_IMAGE="$BASE_IMAGE"} \
  -t "$image" "$repo_root/tests"

tty_opts=()
[[ "${1:-}" == "--shell" ]] && tty_opts=(-it)

# shellcheck disable=SC2086
docker run --rm "${tty_opts[@]}" ${DOCKER_RUN_OPTS:-} \
  -e GITHUB_TOKEN \
  -v "$repo_root:/src:ro" \
  "$image" /src/tests/provision.sh "$@"
