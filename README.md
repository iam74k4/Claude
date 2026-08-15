# Claude グローバル設定リポジトリ

Claude を使う全環境(Claude Code / Claude Desktop / iOS アプリ)の設定を、
この 1 つのリポジトリで一元管理するためのリポジトリです。

## まず理解しておくこと:設定は 2 系統ある

| 系統 | 対象 | 共有方法 |
|------|------|----------|
| **ファイルベース設定** (`~/.claude/`) | Claude Code CLI / VS Code 拡張 (Windows・macOS 共通) | ✅ この Git リポジトリで共有できる |
| **アカウント側設定** (claude.ai) | iOS アプリ / Claude Desktop / Web | ⚙️ claude.ai のアカウントに保存され、**自動で全デバイスに同期**される(ファイルでは管理できない) |

つまり:

- **Claude Code (VS Code / CLI)** → このリポジトリの `home/.claude/` を各マシンにインストールすれば共有完了
- **iOS アプリ / Claude Desktop** → claude.ai の「設定 → プロファイル → 個人設定」に一度書けば全デバイスに同期される。
  貼り付ける内容のマスターを [`claude-ai/preferences.md`](claude-ai/preferences.md) としてこのリポジトリで管理する
- **Claude Desktop の MCP サーバー** (`claude_desktop_config.json`) だけは同期されないので、
  [`desktop/claude_desktop_config.example.json`](desktop/claude_desktop_config.example.json) を各マシンに手動配置する

## リポジトリ構成

```
CLAUDE.md                    ← このリポジトリを Claude Code で開いたとき用の指示
home/                        ← ホームディレクトリのミラー(この下が ~/ にリンクされる)
  .claude/                   ← ~/.claude/ に配置する内容(Claude Code 用)
    CLAUDE.md                ← ユーザーレベルのグローバルメモリ(全プロジェクト共通の指示)
    settings.json            ← 共有する settings(permissions など)
    rules/                   ← 常時適用ルール(CLAUDE.md からインポートされる)
      git.md                 ← Git ルール(ブランチ・コミット・PR の規約)
    skills/                  ← グローバルスキル(該当タスク時に自動発動)
      git-commit/SKILL.md    ← コミット作成の手順スキル
      git-pr/SKILL.md        ← PR 作成の手順スキル
    agents/                  ← カスタムサブエージェント(委譲される専門役)
      code-reviewer.md       ← 変更差分のレビュー(読み取り専用)
      debugger.md            ← エラー・不具合の原因調査と最小修正
      test-runner.md         ← テスト実行・失敗分析・修正
    commands/                ← カスタムスラッシュコマンド
      review.md
    hooks/                   ← Claude Code のフックスクリプト
      sync-config-repo.sh    ← セッション開始時にこのリポジトリを自動 git pull
claude-ai/
  preferences.md             ← claude.ai(iOS/Desktop/Web)に貼る個人設定のマスター
desktop/
  claude_desktop_config.example.json  ← Claude Desktop の MCP 設定の雛形
scripts/
  install.sh                 ← macOS / Linux 用インストーラ(シンボリックリンク作成)
  install.ps1                ← Windows 用インストーラ
```

> `home/` は「ホームディレクトリ(`~/`)にそのまま重なる」ミラー構造。`home/.claude/` が
> `~/.claude/` に対応し、配置先と同じ名前で辿れる。`.claude` をリポジトリ**直下**に
> 置かないのは意図的で、直下に置くと Claude Code がこのリポジトリを開いたときに
> 「プロジェクト設定」として誤認識し、ユーザーレベルと二重に読み込んでしまうため。
> `.claude` は隠しディレクトリなので、Finder / エクスプローラーでは隠しファイル表示を有効にすること。

## ルールとスキルの仕組み(Main workspace として常時参照される理由)

インストーラが `~/.claude/` にリンクを張ることで、**どのリポジトリで開発していても**
Claude Code は常にこのリポジトリの内容を参照します:

- **`home/.claude/rules/*.md`(ルール)** — `home/.claude/CLAUDE.md` が `@~/.claude/rules/git.md` の形で
  インポートしており、**全プロジェクトのすべての会話に常時読み込まれる**。
  「常に守ってほしい規約」はここに書く。
- **`home/.claude/skills/<name>/SKILL.md`(スキル)** — 常時読み込まれるのは説明文だけで、
  **該当するタスク(コミット作成、PR 作成など)のときに本文が自動で読み込まれる**。
  「特定の作業の詳しい手順」はここに書く。
- ルールを増やすときは `home/.claude/rules/` に Markdown を追加し、`home/.claude/CLAUDE.md` に
  `@~/.claude/rules/<ファイル名>.md` の 1 行を足す。
- スキルを増やすときは `home/.claude/skills/<スキル名>/SKILL.md` を追加するだけでよい
  (frontmatter の `description` がいつ発動するかの条件になる)。
- **`home/.claude/agents/<name>.md`(サブエージェント)** — 特定の役割(レビュー、デバッグ等)を
  **独立したコンテキストで実行する専門エージェント**。メイン会話を汚さずに重い調査・検証を
  任せられる。frontmatter の `description` に該当する作業が来ると自動で委譲されるほか、
  「code-reviewer でレビューして」のように名指しでも呼べる。`tools` で使えるツールを
  絞れる(例: code-reviewer は読み取り専用)。追加はファイルを 1 つ置くだけでよい。

いずれも commit → 各マシンで `git pull` すれば即座に全プロジェクトへ反映されます。

> **設計上の割り切り**: `rules/` `skills/` `agents/` `commands/` `hooks/` はディレクトリごと
> シンボリックリンクするため、マシン固有(Git 管理外)のスキルやコマンドを置く場所は
> 意図的にありません。すべてこのリポジトリで管理します。マシン固有の上書きが必要な場合は、
> 作業する側のプロジェクトに `.claude/settings.local.json`(プロジェクト単位・Git 管理外)を
> 置きます(ユーザーレベルの settings.local.json という仕組みは存在しません)。

## 自動同期(常に最新のルールが参照される仕組み)

`settings.json` に **SessionStart フック**を定義してあり、Claude Code のセッションを
開始するたびに `hooks/sync-config-repo.sh` が走って**このリポジトリを自動で `git pull`** します。
どのリポジトリで作業を始めても、その時点の最新ルール・スキルが読み込まれます。

- リポジトリの場所は `~/.claude/CLAUDE.md` のリンク先から自動で特定するため、クローン先は自由
- オフライン時や取得失敗時は黙って何もしない(セッション開始を妨げない)
- ローカルに未コミットの変更がある場合は `--ff-only` により安全側で何もしない
- インストーラがコピー運用にフォールバックしたマシン(シンボリックリンク不可)では
  自動同期は働かないため、手動で `git pull` + インストーラ再実行が必要

## セットアップ手順

### 1. Claude Code(VS Code 拡張 / CLI) — Windows・macOS 共通

VS Code 拡張と CLI は同じ `~/.claude/`(Windows は `%USERPROFILE%\.claude\`)を読むので、
一度設定すれば両方に効きます。

**macOS / Linux:**

```bash
git clone https://github.com/iam74k4/claude.git ~/claude-config
~/claude-config/scripts/install.sh
```

**Windows (PowerShell):**

```powershell
git clone https://github.com/iam74k4/claude.git $HOME\claude-config
powershell -ExecutionPolicy Bypass -File $HOME\claude-config\scripts\install.ps1
```

スクリプトは `~/.claude/` 内の `CLAUDE.md` / `settings.json` / `commands/` / `rules/` /
`skills/` / `agents/` / `hooks/` をこのリポジトリへのシンボリックリンクに置き換えます
(既存ファイルはバックアップされます)。
以後、設定を変えて commit & push すれば、他マシンには**次のセッション開始時に自動反映**されます
(後述の SessionStart フック)。リポジトリ側でディレクトリ構成が変わった場合
(リンク先が切れた場合)のみ、`git pull` 後にインストーラを再実行してください。

> マシン・プロジェクト固有の permissions 上書きは、作業するプロジェクト側の
> `.claude/settings.local.json`(Git 管理外)で行えます。

### 2. iOS アプリ / Claude Desktop / claude.ai Web

これらはローカルファイルを読みません。設定はすべてアカウント側です。

1. [`claude-ai/preferences.md`](claude-ai/preferences.md) の内容をコピー
2. claude.ai(Web か Desktop)の **設定 → プロファイル → 「Claude に覚えておいてほしいこと(個人設定)」** に貼り付け
3. 保存すると **iOS / Desktop / Web すべてに自動同期** される

内容を変えたいときは、まずこのリポジトリの `preferences.md` を更新してから claude.ai に貼り直します
(リポジトリ = マスター、claude.ai = 反映先、という運用)。

### 3. Claude Desktop の MCP サーバー(任意)

Claude Desktop の MCP 設定だけはアカウント同期されないため、各マシンで配置します。

- macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`
- Windows: `%APPDATA%\Claude\claude_desktop_config.json`

[`desktop/claude_desktop_config.example.json`](desktop/claude_desktop_config.example.json) を
上記パスにコピーし、MCP サーバーの引数(許可ディレクトリ等)を各マシンに合わせて
編集してください(JSON にはコメントを書けないため、説明はこの README に置いています)。

### 4. プロジェクト単位で MCP を共有したい場合

作業リポジトリのルートに `.mcp.json` をコミットすると、そのリポジトリを開いた
Claude Code 全員(全マシン)で MCP サーバーが共有されます。ユーザー全体で共有したい
MCP は `claude mcp add --scope user` で追加します(`~/.claude.json` に保存。
認証情報を含むことがあるためこのリポジトリでは管理しません)。

## 各環境の対応表(何がどこで効くか)

| 設定 | Claude Code (VSCode/CLI) | Claude Desktop | iOS アプリ |
|------|:---:|:---:|:---:|
| `~/.claude/CLAUDE.md`(グローバルメモリ) | ✅ | ❌ | ❌ |
| `~/.claude/settings.json` | ✅ | ❌ | ❌ |
| カスタムコマンド / スキル / サブエージェント(`~/.claude/`) | ✅ | ❌ | ❌ |
| claude.ai の個人設定(プロファイル) | ❌ | ✅(同期) | ✅(同期) |
| claude.ai の Projects / メモリ / コネクタ | ❌ | ✅(同期) | ✅(同期) |
| `claude_desktop_config.json`(MCP) | ❌ | ✅(手動配置) | ❌ |
| リポジトリの `CLAUDE.md` / `.mcp.json` | ✅ | ❌ | ❌ |

## 日常の運用フロー

1. 設定を変えたくなったら、このリポジトリを編集して commit & push
2. 他のマシンには**次のセッション開始時に自動反映**される(SessionStart フックが pull する)。
   すぐ反映したい場合や、リポジトリのディレクトリ構成が変わった場合のみ、
   手動で `git pull`(+ 構成変更時はインストーラ再実行)
3. `claude-ai/preferences.md` を変えた場合のみ、claude.ai の設定画面に貼り直す
