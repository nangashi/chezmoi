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

# 本番ではbrewで入れているブートストラップ用ツール（バージョン固定）
RUN mkdir -p ~/.local/bin \
 && curl -fsSL "https://github.com/twpayne/chezmoi/releases/download/v${CHEZMOI_VERSION}/chezmoi_${CHEZMOI_VERSION}_linux_amd64.tar.gz" \
      | tar -xz -C ~/.local/bin chezmoi \
 && curl -fsSL -o ~/.local/bin/mise \
      "https://github.com/jdx/mise/releases/download/v${MISE_VERSION}/mise-v${MISE_VERSION}-linux-x64" \
 && chmod +x ~/.local/bin/mise
ENV PATH=/home/tester/.local/bin:$PATH
