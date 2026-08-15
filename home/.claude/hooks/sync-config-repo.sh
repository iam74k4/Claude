#!/usr/bin/env bash
# SessionStart フック: セッション開始時にこの設定リポジトリを最新化する。
# ~/.claude/CLAUDE.md のシンボリックリンク先からリポジトリの場所を特定するため、
# クローン先がどこでも動く。リンクでない場合(コピー運用)は何もしない。
#
# 注意: SessionStart フックの stdout は Claude のコンテキストに注入されるため、
# このスクリプトは成功・失敗にかかわらず一切出力しない。
set -u

dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
link="$dir/CLAUDE.md"

[ -L "$link" ] || exit 0
target="$(readlink "$link")" || exit 0
# <repo>/home/.claude/CLAUDE.md → <repo>
repo="$(cd "$(dirname "$target")/../.." 2>/dev/null && pwd)" || exit 0

git -C "$repo" pull --ff-only --quiet >/dev/null 2>&1 || true
exit 0
