#!/bin/bash
# repo-sync.sh - GitHubリポジトリ同期スクリプト
#
# 現在のディレクトリ名と同名のGitHubリポジトリを作成またはcloneして同期します
# 新規作成時は空コミットでmainブランチを初期化します

set -euo pipefail

# 色付きメッセージ用の関数
info() {
    echo "ℹ️  $1"
}

success() {
    echo "✅ $1"
}

error() {
    echo "❌ エラー: $1" >&2
    exit 1
}

warn() {
    echo "⚠️  警告: $1"
}

# 1. 事前チェック - ghコマンドの存在確認
if ! command -v gh &> /dev/null; then
    error "ghコマンドが見つかりません。mise install gh を実行してください"
fi

# 2. 事前チェック - GitHub認証状態の確認
if ! gh auth status &> /dev/null; then
    error "GitHub認証が必要です。gh auth login を実行してください"
fi

# 3. 現在のディレクトリ情報取得
CURRENT_DIR=$(basename "$PWD")
info "現在のディレクトリ: $CURRENT_DIR"

# GitHubユーザー名を取得
GH_USER=$(gh api user -q .login) || error "GitHubユーザー名の取得に失敗しました"
REPO_NAME="$GH_USER/$CURRENT_DIR"
info "対象リポジトリ: $REPO_NAME"

# 4. GitHubリポジトリの存在確認
info "GitHubリポジトリの存在を確認中..."
if gh repo view "$REPO_NAME" &> /dev/null; then
    # ============================================================
    # リポジトリが存在する場合の処理
    # ============================================================
    success "GitHubリポジトリが見つかりました: $REPO_NAME"

    # ローカルがgitリポジトリかチェック
    if [ -d ".git" ]; then
        # remoteの確認
        if git remote get-url origin &> /dev/null; then
            CURRENT_REMOTE=$(git remote get-url origin)
            EXPECTED_REMOTE="https://github.com/$REPO_NAME.git"
            EXPECTED_REMOTE_SSH="git@github.com:$REPO_NAME.git"

            if [[ "$CURRENT_REMOTE" == "$EXPECTED_REMOTE" ]] || [[ "$CURRENT_REMOTE" == "$EXPECTED_REMOTE_SSH" ]]; then
                success "既に同期済みです"
                info "Remote URL: $CURRENT_REMOTE"
                exit 0
            else
                warn "異なるリモートが設定されています"
                info "現在: $CURRENT_REMOTE"
                info "期待: $EXPECTED_REMOTE"

                read -p "リモートURLを上書きしますか? (y/N): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    git remote set-url origin "$EXPECTED_REMOTE" || error "リモートURLの変更に失敗しました"
                    success "リモートURLを更新しました: $EXPECTED_REMOTE"
                else
                    info "処理をキャンセルしました"
                    exit 0
                fi
            fi
        else
            # remoteが未設定の場合
            REPO_URL="https://github.com/$REPO_NAME.git"
            git remote add origin "$REPO_URL" || error "リモートの追加に失敗しました"
            success "リモートを追加しました: $REPO_URL"

            # mainブランチがあればpush
            if git rev-parse --verify main &> /dev/null; then
                info "mainブランチをプッシュ中..."
                git push -u origin main || warn "プッシュに失敗しました。手動で確認してください"
                success "mainブランチをプッシュしました"
            fi
        fi
    else
        # ローカルがgitリポジトリでない場合
        warn "このディレクトリはgitリポジトリではありません"

        # ディレクトリが空かチェック
        if [ -n "$(ls -A)" ]; then
            warn "ディレクトリが空ではありません"
            info "既存のファイルがある場合、別ディレクトリへのcloneを推奨します"

            read -p "別ディレクトリにcloneしますか? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                CLONE_DIR="${CURRENT_DIR}_cloned"
                info "cloneディレクトリ: $CLONE_DIR"
                gh repo clone "$REPO_NAME" "$CLONE_DIR" || error "cloneに失敗しました"
                success "cloneしました: $CLONE_DIR"
                exit 0
            else
                error "処理をキャンセルしました"
            fi
        else
            # ディレクトリが空の場合、cloneしてディレクトリを置き換え
            info "空のディレクトリにclone中..."
            cd ..
            TEMP_DIR="${CURRENT_DIR}_temp"
            gh repo clone "$REPO_NAME" "$TEMP_DIR" || error "cloneに失敗しました"
            rm -rf "$CURRENT_DIR"
            mv "$TEMP_DIR" "$CURRENT_DIR"
            cd "$CURRENT_DIR"
            success "cloneしました: $CURRENT_DIR"
        fi
    fi
else
    # ============================================================
    # リポジトリが存在しない場合の処理
    # ============================================================
    info "GitHubリポジトリが見つかりません。新規作成します"

    # リポジトリ作成
    info "パブリックリポジトリを作成中..."
    if ! gh repo create "$CURRENT_DIR" --public --source=. &> /dev/null; then
        error "リポジトリの作成に失敗しました"
    fi
    success "リポジトリを作成しました: $REPO_NAME"

    # ローカルがgitリポジトリでない場合は初期化
    if [ ! -d ".git" ]; then
        info "ローカルリポジトリを初期化中..."
        git init || error "git initに失敗しました"

        # 空コミットを作成してmainブランチを確立
        info "初期コミットを作成中..."
        git commit --allow-empty -m "Initial commit" || error "初期コミットの作成に失敗しました"

        # mainブランチに変更
        git branch -M main || error "mainブランチへの変更に失敗しました"
        success "空コミットでmainブランチを初期化しました"
    fi

    # remoteが未設定の場合は追加
    if ! git remote get-url origin &> /dev/null; then
        REPO_URL="https://github.com/$REPO_NAME.git"
        git remote add origin "$REPO_URL" || error "リモートの追加に失敗しました"
        success "リモートを追加しました: $REPO_URL"
    fi

    # GitHubにプッシュ
    info "GitHubにプッシュ中..."
    git push -u origin main || error "プッシュに失敗しました"
    success "GitHubと同期しました"
fi

# 最終メッセージ
echo ""
success "🎉 同期完了!"
info "リポジトリURL: https://github.com/$REPO_NAME"
