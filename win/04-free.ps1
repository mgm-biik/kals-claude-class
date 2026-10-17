# KALS class, step 6 (Windows): install the `kals-free` command and open Claude Code through the
# local freellmapi gateway. The gateway settings live only in that one Claude Code process, so
# plain `claude` keeps using the paid plan.
# Usage (PowerShell): irm <raw url>/win/04-free.ps1 | iex
# Written for Windows PowerShell 5.1. Never call `exit`: under `irm | iex` it would close the window.

function Invoke-KalsFree {
    $ErrorActionPreference = 'Continue'
    $kalsHome = Join-Path $env:USERPROFILE '.kals'
    $binDir = Join-Path $env:USERPROFILE '.local\bin'
    $launcherPs1 = Join-Path $kalsHome 'kals-free.ps1'
    $launcherCmd = Join-Path $binDir 'kals-free.cmd'

    $launcher = @'
# kals-free: open Claude Code through the local freellmapi gateway, for this session only.
#   kals-free               start (asks for the freellmapi unified key the first time)
#   kals-free --reset-key   forget the saved key and ask again
#   kals-free -p "hi"       any other arguments go to claude
$ErrorActionPreference = 'Continue'
$keyFile = Join-Path $env:USERPROFILE '.kals\freellmapi.key'
$defaultPort = 31415
$configFile = Join-Path $env:APPDATA 'FreeLLMAPI\config.json'
$keyPrefix = 'freellmapi-'
# Groq rejects max_tokens above 16384 and Claude Code asks for more, so cap the output.
$maxOutputTokens = '16000'
$gatewayVars = @('ANTHROPIC_BASE_URL', 'ANTHROPIC_AUTH_TOKEN', 'ANTHROPIC_API_KEY', 'CLAUDE_CODE_MAX_OUTPUT_TOKENS', 'GPTAKU_ROUTER')

function ConvertTo-PlainText([Security.SecureString]$secure) {
    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try { return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }
}

$claudeArgs = @($args)
if ($claudeArgs.Count -gt 0 -and $claudeArgs[0] -eq '--reset-key') {
    Remove-Item $keyFile -Force -ErrorAction SilentlyContinue
    $claudeArgs = @($claudeArgs | Select-Object -Skip 1)
}

$port = $defaultPort
if (Test-Path $configFile) {
    try { $configured = (Get-Content $configFile -Raw | ConvertFrom-Json).port; if ($configured) { $port = [int]$configured } } catch { $port = $defaultPort }
}
$base = "http://127.0.0.1:$port"
try { Invoke-WebRequest -UseBasicParsing -TimeoutSec 3 "$base/health" | Out-Null }
catch { Write-Host "[XX] freellmapi 가 꺼져 있습니다 ($base). FreeLLMAPI 앱을 켠 뒤 다시 실행하세요." -ForegroundColor Red; return }

$key = $null
if (Test-Path $keyFile) {
    try { $key = ConvertTo-PlainText ((Get-Content $keyFile -Raw).Trim() | ConvertTo-SecureString) } catch { $key = $null }
}
if (-not $key) {
    Write-Host 'freellmapi 앱 - Claude Code 카드 - 수동 연결의 API_KEY(통합 키)를 복사해 오세요.'
    $typed = Read-Host '통합 키를 붙여넣고 Enter (화면에 보이지 않습니다)' -AsSecureString
    $key = (ConvertTo-PlainText $typed).Trim()
    if (-not $key.StartsWith($keyPrefix)) { Write-Host "[XX] $keyPrefix 로 시작하는 키가 아닙니다. 다시 복사해 오세요." -ForegroundColor Red; return }
    try { Invoke-WebRequest -UseBasicParsing -TimeoutSec 5 -Headers @{ Authorization = "Bearer $key" } "$base/v1/models" | Out-Null }
    catch { Write-Host '[XX] freellmapi 가 이 키를 받지 않았습니다. 앱에서 키를 다시 복사하세요.' -ForegroundColor Red; return }
    New-Item -ItemType Directory -Force -Path (Split-Path $keyFile) | Out-Null
    # DPAPI: only this Windows user on this computer can decrypt the saved file.
    ConvertTo-SecureString $key -AsPlainText -Force | ConvertFrom-SecureString | Set-Content -Path $keyFile -Encoding ASCII
    Write-Host '[OK] 키를 이 Windows 사용자만 풀 수 있게 암호화해 저장했습니다.' -ForegroundColor Green
}

$claudeExe = Join-Path $env:USERPROFILE '.local\bin\claude.exe'
if (-not (Test-Path $claudeExe)) {
    $found = Get-Command claude -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $found) { Write-Host '[XX] claude 를 찾지 못했습니다. 02-install-claude 를 먼저 실행하세요.' -ForegroundColor Red; return }
    $claudeExe = $found.Source
}

$saved = @{}
foreach ($name in $gatewayVars) { $saved[$name] = [Environment]::GetEnvironmentVariable($name, 'Process') }
try {
    [Environment]::SetEnvironmentVariable('ANTHROPIC_API_KEY', $null, 'Process')
    $env:ANTHROPIC_BASE_URL = $base
    $env:ANTHROPIC_AUTH_TOKEN = $key
    $env:CLAUDE_CODE_MAX_OUTPUT_TOKENS = $maxOutputTokens
    # insane-design's gptaku-core adds skill-routing rules to every prompt; small free models get confused by them.
    $env:GPTAKU_ROUTER = 'off'
    & $claudeExe @claudeArgs
}
finally {
    foreach ($name in $gatewayVars) { [Environment]::SetEnvironmentVariable($name, $saved[$name], 'Process') }
}
'@

    $cmd = "@echo off`r`npowershell.exe -NoProfile -ExecutionPolicy Bypass -File `"%USERPROFILE%\.kals\kals-free.ps1`" %*`r`n"

    New-Item -ItemType Directory -Force -Path $kalsHome, $binDir | Out-Null
    # The launcher runs with -File, so it needs a UTF-8 BOM for Windows PowerShell 5.1 to read Korean text.
    [IO.File]::WriteAllText($launcherPs1, $launcher, (New-Object Text.UTF8Encoding $true))
    [IO.File]::WriteAllText($launcherCmd, $cmd, (New-Object Text.ASCIIEncoding))

    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if (-not $userPath -or ($userPath.Split(';') -notcontains $binDir)) {
        Write-Host "  [!!] 사용자 PATH에 $binDir 이 없습니다. 02-install-claude 를 먼저 실행하세요." -ForegroundColor Yellow
    }

    Write-Host "  [OK] kals-free 명령을 설치했습니다: $launcherCmd" -ForegroundColor Green
    Write-Host '       다음부터는 터미널에서 kals-free 만 치면 됩니다. 창을 닫으면 무료 연결도 함께 끝납니다.'
    Write-Host ''
    & $launcherCmd
}

Invoke-KalsFree
