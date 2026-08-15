# このリポジトリについて

Claude の全環境設定を一元管理する dotfiles リポジトリ。**ここでの編集は、
インストール済みの全マシン・全プロジェクトの Claude Code に波及する**ことを常に意識すること。

## 構造と反映経路

- `dot-claude/` — `~/.claude/` の実体。インストーラがシンボリックリンクを張るため、
  ここを編集して commit → 各マシンで `git pull` するだけで反映される。
  - `CLAUDE.md` はユーザーレベルのグローバルメモリ(このファイルとは別物)
  - `rules/*.md` は常時適用ルール。`dot-claude/CLAUDE.md` からの `@~/.claude/rules/<name>.md`
    インポートで読み込まれるため、**rules にファイルを足したら必ずインポート行も足す**
  - `skills/<name>/SKILL.md` はタスク発動型スキル。frontmatter の `description` が発動条件
  - `agents/<name>.md` はカスタムサブエージェント。frontmatter(`name` / `description` /
    `tools`)+ 本文がシステムプロンプト。役割に不要なツールは `tools` で絞ること
    (例: レビュー役に Edit を与えない)
- `claude-ai/preferences.md` — claude.ai(iOS/Desktop/Web)用マスター。編集しても
  自動反映されない。**変更後は claude.ai のプロファイル設定への貼り直しが必要**な旨を
  ユーザーに案内すること
- `desktop/` — Claude Desktop の MCP 雛形。各マシン手動配置
- `scripts/` — インストーラ。`dot-claude/` 直下に配布物を追加した場合は
  install.sh と install.ps1 の両方の TARGETS リストに追記すること

## 編集時のルール

- `rules/`・`skills/`・`agents/`・`commands/` はディレクトリごとリンクされる設計。
  マシン固有(Git 管理外)のスキルやコマンドを置く場所は意図的に用意していない。
  すべて Git 管理する方針を崩さないこと
- 秘密情報(API キー、トークン、認証情報を含む MCP 設定)は絶対にコミットしない。
  認証が必要な MCP はユーザースコープ(`claude mcp add --scope user`)を案内する
- README のディレクトリツリー図はファイル構成を変えたら更新する
