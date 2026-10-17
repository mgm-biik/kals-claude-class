# KALS class, step 4 (Windows): install insane-design and HyperFrames from the copies 01-prereq
# downloaded at home, then connect REA as an MCP server. Run after logging in to Claude Code.
# Usage (PowerShell): irm <raw url>/win/03-skills.ps1 | iex      ($env:KALS_SKIP_REA='1' skips REA)
# Written for Windows PowerShell 5.1. Never call `exit`: under `irm | iex` it would close the window.

function Invoke-KalsSkills {
    $ErrorActionPreference = 'Continue'
    $kalsHome = Join-Path $env:USERPROFILE '.kals'
    $gptakuDir = Join-Path $kalsHome 'gptaku_plugins'
    $hyperframesDir = Join-Path $kalsHome 'hyperframes'
    $claudeJson = Join-Path $env:USERPROFILE '.claude.json'
    # Remote fallback clones are large; give git more than the default 120 s.
    $env:CLAUDE_CODE_PLUGIN_GIT_TIMEOUT_MS = '300000'

    $script:kalsSkillFailures = 0

    function Say([string]$m) { Write-Host ''; Write-Host "==> $m" -ForegroundColor Cyan }
    function Ok([string]$m) { Write-Host "  [OK] $m" -ForegroundColor Green }
    function Warn([string]$m) { Write-Host "  [!!] $m" -ForegroundColor Yellow }
    function Fail([string]$m) { Write-Host "  [XX] $m" -ForegroundColor Red; $script:kalsSkillFailures++ }

    $claude = Join-Path $env:USERPROFILE '.local\bin\claude.exe'
    if (-not (Test-Path $claude)) {
        $cmd = Get-Command claude -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $cmd) { Fail 'claude 를 찾지 못했습니다. 02-install-claude 를 먼저 실행하세요.'; return }
        $claude = $cmd.Source
    }
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Fail 'Git이 없습니다. Windows에서 플러그인을 설치하려면 Git이 필요합니다. 01-prereq 를 실행하세요.'; return }

    function Add-Marketplace([string]$name, [string]$localDir, [string]$remote) {
        $listed = (& $claude plugin marketplace list 2>&1 | Out-String)
        if ($listed -match [regex]::Escape($name)) { Ok "마켓플레이스 $name 이미 등록됨"; return $true }
        $source = $remote
        if (Test-Path (Join-Path $localDir '.claude-plugin')) { $source = $localDir }
        else { Warn "미리 받은 $name 이 없어 인터넷에서 받습니다. 수백 MB라 오래 걸릴 수 있습니다." }
        & $claude plugin marketplace add $source | Out-Host
        if ($LASTEXITCODE -ne 0) { Fail "마켓플레이스 $name 등록 실패"; return $false }
        Ok "마켓플레이스 $name 등록"
        return $true
    }

    function Install-Plugin([string]$id) {
        $listed = (& $claude plugin list 2>&1 | Out-String)
        if ($listed -match [regex]::Escape($id)) { Ok "$id 이미 설치됨"; return }
        & $claude plugin install $id | Out-Host
        if ($LASTEXITCODE -ne 0) {
            # Windows sometimes fails a plugin copy with EPERM while antivirus scans the files; retry once.
            Start-Sleep -Seconds 3
            & $claude plugin install $id | Out-Host
        }
        if ($LASTEXITCODE -eq 0) { Ok "$id 설치" } else { Fail "$id 설치 실패 - 이 화면을 강사에게 보여 주세요" }
    }

    # Work from .kals: git refuses some operations in a home folder owned by another account ("unsafe location").
    New-Item -ItemType Directory -Force -Path $kalsHome | Out-Null
    Push-Location $kalsHome
    try {
        Say '1/3 insane-design (웹사이트 디자인을 분석하고 그 스타일로 만들어 주는 스킬)'
        if (Add-Marketplace -name 'gptaku-plugins' -localDir $gptakuDir -remote 'fivetaku/gptaku_plugins') { Install-Plugin -id 'insane-design@gptaku-plugins' }

        Say '2/3 HyperFrames (HTML로 영상을 만드는 스킬)'
        if (Add-Marketplace -name 'hyperframes' -localDir $hyperframesDir -remote 'heygen-com/hyperframes') { Install-Plugin -id 'hyperframes@hyperframes' }

        Say '3/3 REA (역분석 도구, MCP 서버로 연결)'
        if ($env:KALS_SKIP_REA -eq '1') { Warn 'KALS_SKIP_REA=1 이라 건너뜁니다' }
        elseif ((Test-Path $claudeJson) -and (Select-String -Path $claudeJson -SimpleMatch '"rea"' -Quiet)) { Ok 'REA 이미 연결됨' }
        else {
            # npx.cmd avoids the npx.ps1 launcher that a strict execution policy blocks.
            # REA prints its whole plan for every supported client; keep it in a log and report the outcome.
            New-Item -ItemType Directory -Force -Path $kalsHome | Out-Null
            $reaLog = Join-Path $kalsHome 'rea-setup.log'
            npx.cmd --yes rea-agents@latest setup --client claude_code --yes *> $reaLog
            if ((Test-Path $claudeJson) -and (Select-String -Path $claudeJson -SimpleMatch '"rea"' -Quiet)) { Ok 'REA 연결 (되돌리려면 npx rea-agents uninstall)' }
            else { Fail "REA 연결 실패 - 기록: $reaLog (수업 뒤에 다시 시도해도 됩니다)" }
        }

    }
    finally { Pop-Location }

    Write-Host ''
    if ($script:kalsSkillFailures -gt 0) { Write-Host "실패한 항목이 $script:kalsSkillFailures 개 있습니다. 위의 [XX] 줄을 강사에게 보여 주세요." -ForegroundColor Yellow }
    else { Write-Host '설치가 끝났습니다.' -ForegroundColor Green }
    Write-Host '열려 있는 Claude Code가 있으면 /exit 로 닫고 claude 로 다시 연 뒤, /plugin 과 /mcp 로 확인합니다.'
}

Invoke-KalsSkills
