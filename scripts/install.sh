#!/usr/bin/env bash
# Claude Code 設定インストーラ (macOS / Linux)
# ~/.claude/ 内の対象ファイルを、このリポジトリへのシンボリックリンクに置き換える。
# 既存ファイルは ~/.claude/backup-<日時>/ に退避する。
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
BACKUP_DIR="$CLAUDE_DIR/backup-$(date +%Y%m%d-%H%M%S)"

# リンク対象: リポジトリ内パス → ~/.claude/ 内での名前
TARGETS=(
  ".claude/CLAUDE.md:CLAUDE.md"
  ".claude/settings.json:settings.json"
  ".claude/commands:commands"
  ".claude/rules:rules"
  ".claude/skills:skills"
  ".claude/agents:agents"
)

mkdir -p "$CLAUDE_DIR"

for entry in "${TARGETS[@]}"; do
  src="$REPO_DIR/${entry%%:*}"
  dst="$CLAUDE_DIR/${entry##*:}"

  [ -e "$src" ] || { echo "skip: $src がリポジトリにありません"; continue; }

  # すでに正しいリンクなら何もしない
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    echo "ok:   $dst (設定済み)"
    continue
  fi

  # 既存の実体ファイル/別リンクはバックアップ
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    mkdir -p "$BACKUP_DIR"
    mv "$dst" "$BACKUP_DIR/"
    echo "backup: $dst -> $BACKUP_DIR/"
  fi

  ln -s "$src" "$dst"
  echo "link: $dst -> $src"
done

echo ""
echo "完了。以後は 'git -C $REPO_DIR pull' だけで設定が同期されます。"
if [ -d "$BACKUP_DIR" ]; then
  echo "既存ファイルのバックアップ: $BACKUP_DIR"
fi
