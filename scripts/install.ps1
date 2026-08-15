# Claude Code 設定インストーラ (Windows)
# %USERPROFILE%\.claude\ 内の対象ファイルを、このリポジトリへのシンボリックリンクに置き換える。
# シンボリックリンク作成には「開発者モード」有効化か管理者権限が必要。
# どちらも使えない場合はコピーにフォールバックする(その場合 pull 後に再実行が必要)。
$ErrorActionPreference = "Stop"

$RepoDir = Split-Path -Parent $PSScriptRoot
$ClaudeDir = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $HOME ".claude" }
$BackupDir = Join-Path $ClaudeDir ("backup-" + (Get-Date -Format "yyyyMMdd-HHmmss"))

$Targets = @(
    @{ Src = "home\.claude\CLAUDE.md";     Dst = "CLAUDE.md" },
    @{ Src = "home\.claude\settings.json"; Dst = "settings.json" },
    @{ Src = "home\.claude\commands";      Dst = "commands" },
    @{ Src = "home\.claude\rules";         Dst = "rules" },
    @{ Src = "home\.claude\skills";        Dst = "skills" },
    @{ Src = "home\.claude\agents";        Dst = "agents" },
    @{ Src = "home\.claude\hooks";         Dst = "hooks" }
)

# シンボリックリンクの Target は PowerShell のバージョンによって '\\?\' 接頭辞付きで
# 返ることがあるため、正規化してから比較する(冪等判定のため)
function Get-LinkTarget($item) {
    if (-not $item -or $item.LinkType -ne "SymbolicLink") { return $null }
    $target = @($item.Target)[0]
    if (-not $target) { return $null }
    return ($target -replace '^\\\\\?\\', '')
}

New-Item -ItemType Directory -Force -Path $ClaudeDir | Out-Null

foreach ($t in $Targets) {
    $src = Join-Path $RepoDir $t.Src
    $dst = Join-Path $ClaudeDir $t.Dst

    if (-not (Test-Path $src)) {
        Write-Host "skip: $src がリポジトリにありません"
        continue
    }

    $existing = Get-Item $dst -ErrorAction SilentlyContinue
    $linkTarget = Get-LinkTarget $existing
    if ($linkTarget -and ($linkTarget -ieq $src)) {
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
Write-Host "完了。設定の変更は次のセッション開始時に自動反映されます(コピーの場合は pull 後に本スクリプトを再実行)。"
if (Test-Path $BackupDir) {
    Write-Host "既存ファイルのバックアップ: $BackupDir"
}
