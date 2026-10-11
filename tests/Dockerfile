# dotfiles構築テスト用イメージ（WSL2のUbuntuを想定したまっさらな環境）
ARG BASE_IMAGE=ubuntu:24.04
FROM ${BASE_IMAGE}

ARG CHEZMOI_VERSION=2.73.0
ARG MISE_VERSION=2026.10.7
ARG GOSS_VERSION=0.4.9

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      build-essential ca-certificates curl git locales sudo tmux unzip xz-utils zsh \
 && locale-gen en_US.UTF-8 \
 && rm -rf /var/lib/apt/lists/*
ENV LANG=en_US.UTF-8

RUN curl -fsSL -o /usr/local/bin/goss \
      "https://github.com/goss-org/goss/releases/download/v${GOSS_VERSION}/goss-linux-amd64" \
 && chmod +x /usr/local/bin/goss

# WSL2の初期ユーザー相当の一般ユーザー
RUN useradd -m -s /usr/bin/zsh tester \
 && echo 'tester ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/tester
USER tester
WORKDIR /home/tester

# READMEと同じ公式インストーラで入れる（バージョン固定）
RUN sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin" -t "v${CHEZMOI_VERSION}" \
 && curl -fsSL https://mise.run | MISE_VERSION="v${MISE_VERSION}" sh
ENV PATH=/home/tester/.local/bin:$PATH
