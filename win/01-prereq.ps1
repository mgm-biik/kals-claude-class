# KALS class, run at HOME before class (Windows).
# Installs Git, Node.js LTS, FFmpeg and Python with winget, then pre-downloads the HyperFrames and
# insane-design plugin sources so the class Wi-Fi never has to carry hundreds of MB per student.
# Usage (PowerShell): irm <raw url>/win/01-prereq.ps1 | iex
# Written for Windows PowerShell 5.1. Never call `exit`: under `irm | iex` it would close the window.

function Invoke-KalsPrereq {
    # 'Continue', not 'Stop': in PowerShell 5.1, native stderr under 'Stop' becomes a terminating error.
    $ErrorActionPreference = 'Continue'
    # Replaced with the published raw GitHub base URL when the repository is released.
    $rawBase = 'https://raw.githubusercontent.com/mgm-biik/kals-claude-class/main'
    $kalsHome = Join-Path $env:USERPROFILE '.kals'
    $hyperframesRepo = 'https://github.com/heygen-com/hyperframes'
    $hyperframesDir = Join-Path $kalsHome 'hyperframes'
    # Only the skills and the plugin manifest are needed; the full working tree is about 338 MB.
    $hyperframesSparse = @('skills', '.claude-plugin')
    $gptakuRepo = 'https://github.com/fivetaku/gptaku_plugins'
    $gptakuDir = Join-Path $kalsHome 'gptaku_plugins'
    # Each gptaku plugin is a git submodule except gptaku-core, a plain folder that comes with the clone.
    $gptakuSubmodules = @('plugins/insane-design')
    $minBuild = 17763
    $minFreeGB = 3
    $wingetPackages = @(
        @{ Id = 'Git.Git'; Command = 'git'; Name = 'Git' },
        @{ Id = 'OpenJS.NodeJS.LTS'; Command = 'node'; Name = 'Node.js LTS' },
        @{ Id = 'Gyan.FFmpeg'; Command = 'ffmpeg'; Name = 'FFmpeg' },
        @{ Id = 'Python.Python.3.12'; Command = 'python'; Name = 'Python 3.12' }
    )

    function Say([string]$m) { Write-Host ''; Write-Host "==> $m" -ForegroundColor Cyan }
    function Ok([string]$m) { Write-Host "  [OK] $m" -ForegroundColor Green }
    function Warn([string]$m) { Write-Host "  [!!] $m" -ForegroundColor Yellow }
    function Fail([string]$m) { Write-Host "  [XX] $m" -ForegroundColor Red }

    # winget installs change PATH in the registry only; reload it so this window sees new commands.
    function Update-SessionPath {
        $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
        $user = [Environment]::GetEnvironmentVariable('Path', 'User')
        $env:Path = "$machine;$user"
    }

    # The real executable for a command, skipping the Microsoft Store stubs in WindowsApps.
    function Get-RealCommand([string]$name) {
        return Get-Command $name -All -CommandType Application -ErrorAction SilentlyContinue | Where-Object { $_.Source -notlike '*WindowsApps*' } | Select-Object -First 1
    }

    function Get-CommandVersion([string]$name) {
        $cmd = Get-RealCommand $name
        if (-not $cmd) { return $null }
        $m = [regex]::Match((& $cmd.Source --version 2>&1 | Out-String), '(\d+)\.(\d+)(?:\.(\d+))?')
        if (-not $m.Success) { return New-Object Version 0, 0, 0 }
        $patch = 0
        if ($m.Groups[3].Success) { $patch = [int]$m.Groups[3].Value }
        return New-Object Version ([int]$m.Groups[1].Value), ([int]$m.Groups[2].Value), $patch
    }

    # REA accepts Node 22.19+, 24.11+ or 26+; odd majors 23 and 25 are rejected.
    function Test-NodeVersion([Version]$v) {
        if ($v.Major -eq 22) { return $v -ge (New-Object Version 22, 19, 0) }
        if ($v.Major -eq 24) { return $v -ge (New-Object Version 24, 11, 0) }
        if ($v.Major -eq 23 -or $v.Major -eq 25) { return $false }
        return $v.Major -ge 26
    }

    # Node and Python must also be new enough; Git and FFmpeg only need to exist.
    function Test-PackageReady($pkg) {
        if ($pkg.Command -eq 'node') { $v = Get-CommandVersion 'node'; return [bool]($v -and (Test-NodeVersion $v)) }
        if ($pkg.Command -eq 'python') { $v = Get-CommandVersion 'python'; return [bool]($v -and $v -ge (New-Object Version 3, 11, 0)) }
        return [bool](Get-RealCommand $pkg.Command)
    }

    # The python.org installer gives `python` but not `python3`, and insane-design calls `python3`.
    # Returns 'ok', 'missing' (no real python) or 'denied' (python lives in a folder we cannot write).
    function Repair-Python3 {
        if (Get-RealCommand 'python3') { return 'ok' }
        # Prefer the per-user python.org install that winget puts here; fall back to whatever python.exe is first.
        $source = Join-Path $env:LOCALAPPDATA 'Programs\Python\Python312\python.exe'
        if (-not (Test-Path $source)) {
            $real = Get-RealCommand 'python'
            if (-not $real -or $real.Source -notlike '*.exe') { return 'missing' }
            $source = $real.Source
        }
        $target = Join-Path (Split-Path $source) 'python3.exe'
        try { Copy-Item $source $target -Force -ErrorAction Stop; return 'ok' }
        catch { return 'denied' }
    }

    $failures = 0

    Say '1/6 컴퓨터 확인'
    $os = [Environment]::OSVersion.Version
    if ($os.Build -lt $minBuild) { Fail "Windows 빌드 $($os.Build) 입니다. Windows 10 1809 이상이 필요합니다."; return }
    if (-not [Environment]::Is64BitProcess) { Fail '32비트 PowerShell입니다. 시작 메뉴에서 (x86)이 붙지 않은 PowerShell을 열고 다시 실행하세요.'; return }
    $drive = Get-PSDrive -Name ($env:USERPROFILE.Substring(0, 1))
    $freeGB = [math]::Floor($drive.Free / 1GB)
    if ($freeGB -lt $minFreeGB) { Fail "남은 디스크가 ${freeGB}GB 입니다. ${minFreeGB}GB 이상 비운 뒤 다시 실행하세요."; return }
    Ok "Windows 빌드 $($os.Build), 남은 디스크 ${freeGB}GB"
    if ($env:USERPROFILE -match '[^\x21-\x7E]') {
        Warn "사용자 폴더 경로에 한글이나 공백이 있습니다: $env:USERPROFILE"
        Warn '이 경우 일부 플러그인 기능이 Windows에서 오작동합니다. 설치는 계속하되, 수업 전에 강사에게 꼭 알려 주세요.'
    }
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

    Say '2/6 PowerShell 실행 정책'
    # npm's npx.ps1 launcher is blocked under Restricted; RemoteSigned for this user only fixes it.
    if ((Get-ExecutionPolicy -Scope CurrentUser) -in @('Undefined', 'Restricted') -and (Get-ExecutionPolicy) -eq 'Restricted') {
        try { Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force -ErrorAction Stop; Ok '이 사용자만 RemoteSigned 로 바꿨습니다' }
        catch { Warn "실행 정책을 바꾸지 못했습니다(회사 정책일 수 있음): $($_.Exception.Message)" }
    } else { Ok "그대로 둡니다 ($(Get-ExecutionPolicy))" }

    Say '3/6 Git, Node.js, FFmpeg, Python (winget)'
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Fail 'winget 이 없습니다. Microsoft Store에서 "앱 설치 관리자(App Installer)"를 설치한 뒤 다시 실행하세요.'
        return
    }
    foreach ($pkg in $wingetPackages) {
        Update-SessionPath
        if (Test-PackageReady $pkg) { Ok "$($pkg.Name) 이미 있음"; continue }
        Write-Host "  $($pkg.Name) 설치 중... (관리자 권한 창이 뜨면 '예'를 누르세요)"
        winget install --id $pkg.Id --exact --source winget --silent --accept-package-agreements --accept-source-agreements
        Update-SessionPath
        if (Test-PackageReady $pkg) { Ok "$($pkg.Name) 설치" }
        else {
            $failures++
            Warn "$($pkg.Name) 를 준비하지 못했습니다. 오래된 버전이 먼저 잡히거나 설치가 막혔을 수 있습니다. 창을 새로 열고 다시 실행해도 같으면 강사에게 알려 주세요."
        }
    }
    switch (Repair-Python3) {
        'ok' { Ok 'python3 명령 준비' }
        'denied' { $failures++; Warn 'Python이 관리자 폴더에 있어 python3 명령을 만들지 못했습니다. 강사에게 알려 주세요.' }
        default { $failures++; Warn 'Python을 찾지 못해 python3 명령을 만들지 못했습니다. 창을 새로 열고 다시 실행하세요.' }
    }
    if (-not (Get-RealCommand 'git')) { Fail 'Git이 아직 보이지 않습니다. 창을 새로 열고 다시 실행하세요.'; return }
    # Plugin paths can exceed the 260-character Windows limit.
    git config --global core.longpaths true

    Say '4/6 수업용 플러그인 미리 받기 (HyperFrames, insane-design)'
    # core.autocrlf=false keeps LF line endings: Git for Windows would otherwise turn the plugins'
    # shell scripts into CRLF, and Git Bash then fails on them with "$'\r': command not found".
    New-Item -ItemType Directory -Force -Path $kalsHome | Out-Null
    if (Test-Path (Join-Path $hyperframesDir '.claude-plugin\marketplace.json')) { Ok 'HyperFrames 이미 받음' }
    else {
        if (Test-Path $hyperframesDir) { Remove-Item $hyperframesDir -Recurse -Force -ErrorAction SilentlyContinue }
        if (Test-Path $hyperframesDir) { Fail "이전 폴더를 지우지 못했습니다(백신이나 다른 창이 잡고 있을 수 있음): $hyperframesDir - 컴퓨터를 다시 켠 뒤 다시 실행하세요"; return }
        git -c core.autocrlf=false clone -q --depth 1 --filter=blob:none --sparse $hyperframesRepo $hyperframesDir
        git -C $hyperframesDir config core.autocrlf false
        git -c core.autocrlf=false -C $hyperframesDir sparse-checkout set @hyperframesSparse
        if (Test-Path (Join-Path $hyperframesDir '.claude-plugin\marketplace.json')) { Ok 'HyperFrames 받음' } else { Fail 'HyperFrames 받기 실패 - 인터넷 연결을 확인하고 다시 실행하세요'; return }
    }
    if (Test-Path (Join-Path $gptakuDir 'plugins\insane-design\.claude-plugin\plugin.json')) { Ok 'insane-design 이미 받음' }
    else {
        if (Test-Path $gptakuDir) { Remove-Item $gptakuDir -Recurse -Force -ErrorAction SilentlyContinue }
        if (Test-Path $gptakuDir) { Fail "이전 폴더를 지우지 못했습니다(백신이나 다른 창이 잡고 있을 수 있음): $gptakuDir - 컴퓨터를 다시 켠 뒤 다시 실행하세요"; return }
        git -c core.autocrlf=false clone -q --depth 1 $gptakuRepo $gptakuDir
        git -C $gptakuDir config core.autocrlf false
        git -c core.autocrlf=false -C $gptakuDir submodule update -q --init --depth 1 @gptakuSubmodules
        if (Test-Path (Join-Path $gptakuDir 'plugins\insane-design\.claude-plugin\plugin.json')) { Ok 'insane-design 받음' } else { Fail 'insane-design 받기 실패 - 인터넷 연결을 확인하고 다시 실행하세요'; return }
    }

    Say '5/6 영상 렌더용 브라우저와 REA 미리 받기'
    # npx.cmd and npm.cmd avoid the .ps1 launchers that a strict execution policy blocks.
    if (Get-Command npx.cmd -ErrorAction SilentlyContinue) {
        npx.cmd --yes hyperframes@latest browser ensure *> $null
        if ($LASTEXITCODE -eq 0) { Ok 'HyperFrames 렌더 브라우저 준비' } else { Warn '렌더 브라우저 준비 실패 - 수업에서 다시 시도합니다' }
        npm.cmd cache add rea-agents@latest *> $null
        if ($LASTEXITCODE -eq 0) { Ok 'REA 패키지 미리 받음' } else { Warn 'REA 미리 받기 실패 - 수업에서 받습니다' }
    } else { $failures++; Warn 'Node.js(npx)가 없어 이 단계를 건너뜁니다. 3단계 Node.js 문제를 먼저 해결하세요.' }

    Say '6/6 결과'
    if ($failures -eq 0) { Write-Host '사전 준비가 끝났습니다.' -ForegroundColor Green }
    else { Write-Host "준비하지 못한 항목이 $failures 개 있습니다. 위의 [!!] 줄을 확인하고, 모르겠으면 이 화면을 캡처해 강사에게 보내 주세요." -ForegroundColor Yellow }
    Write-Host '30초쯤 기다렸다가 새 터미널 탭(또는 새 PowerShell 창)을 열고, 아래로 전체 상태를 확인해 보세요.'
    Write-Host "  irm $rawBase/win/00-doctor.ps1 | iex"
}

Invoke-KalsPrereq
