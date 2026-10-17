# KALS class (Windows): undo gateway settings that can redirect every Claude Code session.
# - removes ANTHROPIC_* keys from %USERPROFILE%\.claude\settings.json (left there by
#   `npx freellmapi setup-claude`) after saving a timestamped backup
# - removes ANTHROPIC_* user environment variables saved with setx
# - reports PowerShell profiles that set ANTHROPIC_* (it does not edit them)
# - optionally deletes the saved kals-free key
# Plugins stay installed. Usage (PowerShell): irm <raw url>/win/99-restore.ps1 | iex
# Written for Windows PowerShell 5.1. Never call `exit`: under `irm | iex` it would close the window.

function Invoke-KalsRestore {
    $ErrorActionPreference = 'Continue'
    $settings = Join-Path $env:USERPROFILE '.claude\settings.json'
    $keyFile = Join-Path $env:USERPROFILE '.kals\freellmapi.key'
    $gatewayKeys = @('ANTHROPIC_BASE_URL', 'ANTHROPIC_AUTH_TOKEN', 'ANTHROPIC_API_KEY', 'ANTHROPIC_MODEL',
        'ANTHROPIC_DEFAULT_OPUS_MODEL', 'ANTHROPIC_DEFAULT_SONNET_MODEL', 'ANTHROPIC_DEFAULT_HAIKU_MODEL',
        'CLAUDE_CODE_AUTO_COMPACT_WINDOW', 'CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY')
    $userEnvKeys = @('ANTHROPIC_BASE_URL', 'ANTHROPIC_AUTH_TOKEN', 'ANTHROPIC_API_KEY', 'CLAUDE_CODE_MAX_OUTPUT_TOKENS')

    function Say([string]$m) { Write-Host ''; Write-Host "==> $m" -ForegroundColor Cyan }
    function Ok([string]$m) { Write-Host "  [OK] $m" -ForegroundColor Green }
    function Warn([string]$m) { Write-Host "  [!!] $m" -ForegroundColor Yellow }

    Say '1/4 전역 설정(settings.json)'
    if ((Test-Path $settings) -and (Select-String -Path $settings -Pattern '"ANTHROPIC_(BASE_URL|AUTH_TOKEN|API_KEY)"' -Quiet)) {
        if (-not (Get-Command node -ErrorAction SilentlyContinue)) { Warn 'Node.js가 없어 자동으로 고치지 못합니다. 강사에게 알려 주세요.' }
        else {
            $backup = "$settings.kals-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            try { Copy-Item $settings $backup -ErrorAction Stop }
            catch { Warn "백업을 만들지 못해 아무것도 고치지 않았습니다: $($_.Exception.Message)"; $backup = $null }
        }
        if ((Get-Command node -ErrorAction SilentlyContinue) -and $backup) {
            $env:KALS_KEYS = $gatewayKeys -join ' '
            # Run the JSON edit from a file: Windows PowerShell 5.1 strips double quotes from `node -e` arguments.
            $js = Join-Path $env:TEMP 'kals-restore-settings.js'
            $code = @'
const fs = require("fs");
const path = process.argv[2];
const data = JSON.parse(fs.readFileSync(path, "utf8"));
for (const key of process.env.KALS_KEYS.split(" ")) if (data.env) delete data.env[key];
if (data.env && Object.keys(data.env).length === 0) delete data.env;
fs.writeFileSync(path, JSON.stringify(data, null, 2) + "\n");
'@
            [IO.File]::WriteAllText($js, $code, (New-Object Text.UTF8Encoding $false))
            node $js $settings
            Remove-Item $js, Env:KALS_KEYS -ErrorAction SilentlyContinue
            if ($LASTEXITCODE -eq 0) { Ok "연결 설정을 지웠습니다. 원본은 $backup 에 남겨 두었습니다." }
            else { Warn "고치지 못했습니다. 원본은 그대로이고 백업은 $backup 입니다." }
        }
    } else { Ok '깨끗합니다' }
    $freeBackups = Get-ChildItem -Path "$settings.backup-*" -ErrorAction SilentlyContinue
    if ($freeBackups) { Warn "freellmapi 가 만든 백업이 있습니다: $($freeBackups.Name -join ', ')" }

    Say '2/4 영구 저장된 사용자 환경변수 (setx 로 넣은 것)'
    $removed = @()
    foreach ($name in $userEnvKeys) {
        if ([Environment]::GetEnvironmentVariable($name, 'User')) {
            [Environment]::SetEnvironmentVariable($name, $null, 'User')
            $removed += $name
        }
        # Also clear this window's copy; Orca keeps already-loaded variables in every tab until it restarts.
        Remove-Item "Env:\$name" -ErrorAction SilentlyContinue
    }
    if ($removed) {
        Ok "지웠습니다: $($removed -join ', ')"
        Warn 'Orca는 이미 읽어 둔 환경변수를 계속 씁니다. Orca를 트레이 아이콘까지 완전히 종료한 뒤 다시 실행하세요.'
    } else { Ok '깨끗합니다' }

    Say '3/4 PowerShell 프로필'
    $profiles = @($PROFILE.CurrentUserAllHosts, $PROFILE.CurrentUserCurrentHost) | Select-Object -Unique
    $found = $false
    foreach ($p in $profiles) {
        if ($p -and (Test-Path $p) -and (Select-String -Path $p -SimpleMatch 'ANTHROPIC_' -Quiet)) {
            Warn "$p 에 ANTHROPIC_ 설정이 있습니다(자동으로 고치지 않음)"
            $found = $true
        }
    }
    if (-not $found) { Ok '깨끗합니다' }

    Say '4/4 kals-free 에 저장한 키'
    if (Test-Path $keyFile) {
        $answer = Read-Host '  저장된 freellmapi 키를 지울까요? [y/N]'
        if ($answer -eq 'y' -or $answer -eq 'Y') { Remove-Item $keyFile -Force; Ok '지웠습니다' } else { Ok '그대로 둡니다' }
    } else { Ok '저장된 키 없음' }

    Write-Host ''
    Write-Host '끝났습니다. 새 터미널에서 claude 를 열고 /status 로 로그인 방식이 구독인지 확인하세요.'
}

Invoke-KalsRestore
