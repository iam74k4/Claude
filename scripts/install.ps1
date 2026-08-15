# Claude Code 設定インストーラ (Windows)
# %USERPROFILE%\.claude\ 内の対象ファイルを、このリポジトリへのシンボリックリンクに置き換える。
# シンボリックリンク作成には「開発者モード」有効化か管理者権限が必要。
# どちらも使えない場合はコピーにフォールバックする(その場合 pull 後に再実行が必要)。
$ErrorActionPreference = "Stop"

$RepoDir = Split-Path -Parent $PSScriptRoot
$ClaudeDir = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $HOME ".claude" }
$BackupDir = Join-Path $ClaudeDir ("backup-" + (Get-Date -Format "yyyyMMdd-HHmmss"))

$Targets = @(
    @{ Src = "dot-claude\CLAUDE.md";     Dst = "CLAUDE.md" },
    @{ Src = "dot-claude\settings.json"; Dst = "settings.json" },
    @{ Src = "dot-claude\commands";      Dst = "commands" },
    @{ Src = "dot-claude\rules";         Dst = "rules" },
    @{ Src = "dot-claude\skills";        Dst = "skills" },
    @{ Src = "dot-claude\agents";        Dst = "agents" }
)

New-Item -ItemType Directory -Force -Path $ClaudeDir | Out-Null

foreach ($t in $Targets) {
    $src = Join-Path $RepoDir $t.Src
    $dst = Join-Path $ClaudeDir $t.Dst

    if (-not (Test-Path $src)) {
        Write-Host "skip: $src がリポジトリにありません"
        continue
    }

    $existing = Get-Item $dst -ErrorAction SilentlyContinue
    if ($existing -and $existing.LinkType -eq "SymbolicLink" -and $existing.Target -eq $src) {
        Write-Host "ok:   $dst (設定済み)"
        continue
    }

    if (Test-Path $dst) {
        New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null
        Move-Item $dst (Join-Path $BackupDir $t.Dst)
        Write-Host "backup: $dst -> $BackupDir"
    }

    try {
        New-Item -ItemType SymbolicLink -Path $dst -Target $src | Out-Null
        Write-Host "link: $dst -> $src"
    } catch {
        # 開発者モード無効などでリンクが作れない場合はコピー
        Copy-Item $src $dst -Recurse
        Write-Host "copy: $dst (シンボリックリンク不可のためコピー。git pull 後は再実行してください)"
    }
}

Write-Host ""
Write-Host "完了。以後は 'git -C $RepoDir pull' で設定が同期されます(コピーの場合は本スクリプトを再実行)。"
if (Test-Path $BackupDir) {
    Write-Host "既存ファイルのバックアップ: $BackupDir"
}
