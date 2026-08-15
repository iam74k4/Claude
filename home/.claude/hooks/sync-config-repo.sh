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

before="$(git -C "$repo" rev-parse HEAD 2>/dev/null)" || exit 0
git -C "$repo" pull --ff-only --quiet >/dev/null 2>&1 || exit 0
after="$(git -C "$repo" rev-parse HEAD 2>/dev/null)" || exit 0

# 更新がなければここで終了。更新があった場合のみインストーラを再実行し、
# リンク対象の追加・構成変更(リンク切れ)に自動で追従する。
[ "$before" = "$after" ] && exit 0

case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    # Windows: Git Bash の ln -s は実体コピーになるため、必ず PowerShell 版を使う
    winpath="$(cygpath -w "$repo/scripts/install.ps1" 2>/dev/null)" || exit 0
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$winpath" >/dev/null 2>&1 || true
    ;;
  *)
    bash "$repo/scripts/install.sh" >/dev/null 2>&1 || true
    ;;
esac
exit 0
