# KALS class: read-only health check for Windows. It changes nothing on the machine.
# Usage (PowerShell): irm <raw url>/win/00-doctor.ps1 | iex
# Written for Windows PowerShell 5.1. Never call `exit`: under `irm | iex` it would close the window.

function Invoke-KalsDoctor {
    $ErrorActionPreference = 'Continue'
    $kalsHome = Join-Path $env:USERPROFILE '.kals'
    $defaultPort = 31415
    $minBuild = 17763
    $minFreeGB = 3
    $script:kalsFails = 0
    $script:kalsWarns = 0

    function Ok([string]$m) { Write-Host "  [OK] $m" -ForegroundColor Green }
    function Info([string]$m) { Write-Host "  [--] $m" }
    function Warn([string]$m) { Write-Host "  [!!] $m" -ForegroundColor Yellow; $script:kalsWarns++ }
    function Bad([string]$m) { Write-Host "  [XX] $m" -ForegroundColor Red; $script:kalsFails++ }
    function Section([string]$m) { Write-Host ""; Write-Host $m }

    function Get-VersionFromText([string]$text) {
        $m = [regex]::Match($text, '(\d+)\.(\d+)(?:\.(\d+))?')
        if (-not $m.Success) { return $null }
        $patch = 0
        if ($m.Groups[3].Success) { $patch = [int]$m.Groups[3].Value }
        return New-Object Version ([int]$m.Groups[1].Value), ([int]$m.Groups[2].Value), $patch
    }

    # REA accepts Node 22.19+, 24.11+ or 26+; odd majors 23 and 25 are rejected.
    function Test-NodeForRea([Version]$v) {
        if ($v.Major -eq 22) { return $v -ge (New-Object Version 22, 19, 0) }
        if ($v.Major -eq 24) { return $v -ge (New-Object Version 24, 11, 0) }
        if ($v.Major -eq 23 -or $v.Major -eq 25) { return $false }
        return $v.Major -ge 26
    }

    function Test-Installed([string]$pattern) {
        $roots = @('HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
            'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
            'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*')
        foreach ($root in $roots) {
            $hit = Get-ItemProperty $root -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like $pattern }
            if ($hit) { return $true }
        }
        return $false
    }

    function Get-FreellmapiPort {
        $config = Join-Path $env:APPDATA 'FreeLLMAPI\config.json'
        if (Test-Path $config) {
            try {
                $port = (Get-Content $config -Raw | ConvertFrom-Json).port
                if ($port) { return [int]$port }
            } catch { return $defaultPort }
        }
        return $defaultPort
    }

    Section '1. 컴퓨터'
    $os = [Environment]::OSVersion.Version
    if ($os.Build -ge $minBuild) { Ok "Windows 빌드 $($os.Build)" } else { Bad "Windows 빌드 $($os.Build) - 10 (1809, 빌드 17763) 이상이어야 합니다" }
    $arch = $env:PROCESSOR_ARCHITECTURE
    if ($env:PROCESSOR_ARCHITEW6432) { $arch = $env:PROCESSOR_ARCHITEW6432 }
    if ($arch -eq 'ARM64') { Warn 'ARM 노트북입니다. Orca는 x64 Windows만 지원합니다 - 강사에게 알려 주세요' } else { Ok "CPU $arch" }
    if ([Environment]::Is64BitProcess) { Ok "PowerShell $($PSVersionTable.PSVersion) (64비트)" } else { Bad '32비트 PowerShell입니다. 시작 메뉴에서 (x86)이 붙지 않은 PowerShell을 여세요' }
    $policy = Get-ExecutionPolicy
    if ($policy -eq 'Restricted') { Warn '실행 정책이 Restricted 입니다 - 01-prereq 가 RemoteSigned 로 바꿉니다' } else { Ok "실행 정책 $policy" }
    if ($env:USERPROFILE -match '[^\x21-\x7E]') { Warn "사용자 폴더 경로에 한글이나 공백이 있습니다: $env:USERPROFILE - 일부 플러그인이 오작동합니다. 강사에게 알려 주세요" } else { Ok "사용자 폴더 $env:USERPROFILE" }
    $drive = Get-PSDrive -Name ($env:USERPROFILE.Substring(0, 1)) -ErrorAction SilentlyContinue
    if ($drive) {
        $freeGB = [math]::Floor($drive.Free / 1GB)
        if ($freeGB -ge $minFreeGB) { Ok "남은 디스크 ${freeGB}GB" } else { Bad "남은 디스크 ${freeGB}GB - ${minFreeGB}GB 이상 비워 주세요" }
    }
    if (Get-Command winget -ErrorAction SilentlyContinue) { Ok 'winget 있음' } else { Bad 'winget 없음 - Microsoft Store에서 "앱 설치 관리자"를 설치하세요' }

    Section '2. 미리 설치할 앱'
    if ((Test-Installed 'Orca*') -or (Test-Path (Join-Path $env:LOCALAPPDATA 'Programs\Orca'))) { Ok 'Orca 설치됨' } else { Bad 'Orca가 없습니다 - onorca.dev 에서 설치' }
    if ((Test-Installed '*FreeLLMAPI*') -or (Test-Path (Join-Path $env:LOCALAPPDATA 'Programs\FreeLLMAPI'))) { Ok 'freellmapi 설치됨' } else { Bad 'freellmapi 앱이 없습니다' }
    $port = Get-FreellmapiPort
    try {
        Invoke-WebRequest -UseBasicParsing -TimeoutSec 3 "http://127.0.0.1:$port/health" | Out-Null
        Ok "freellmapi 실행 중 (포트 $port)"
    } catch { Warn "freellmapi가 꺼져 있습니다 (포트 $port) - 실습 전에 앱을 켜 주세요" }

    Section '3. 개발 도구 (01-prereq 가 설치)'
    if (Get-Command git -ErrorAction SilentlyContinue) { Ok (git --version) } else { Bad 'Git 없음 (Windows에서 플러그인을 설치하려면 필요)' }
    if (Get-Command node -ErrorAction SilentlyContinue) {
        $nodeV = Get-VersionFromText (node --version)
        if ($nodeV.Major -lt 22) { Bad "Node.js $nodeV - 22 이상이어야 합니다" }
        elseif (-not (Test-NodeForRea $nodeV)) { Warn "Node.js $nodeV - REA는 22.19+, 24.11+, 26+ 만 받습니다" }
        else { Ok "Node.js $nodeV" }
    } else { Bad 'Node.js 없음' }
    if (Get-Command ffmpeg -ErrorAction SilentlyContinue) { Ok 'FFmpeg' } else { Bad 'FFmpeg 없음 (영상 렌더에 필요)' }
    $py = Get-Command python3 -ErrorAction SilentlyContinue
    if ($py -and $py.Source -notlike '*WindowsApps*') {
        $pyV = Get-VersionFromText (& $py.Source --version 2>&1 | Out-String)
        if ($pyV -and $pyV -ge (New-Object Version 3, 11, 0)) { Ok "Python $pyV (python3)" } else { Bad "Python $pyV - 3.11 이상이어야 합니다" }
    } else { Bad 'python3 명령이 없거나 Microsoft Store 바로가기입니다 - 01-prereq 실행' }
    if (Test-Path (Join-Path $kalsHome 'hyperframes\.claude-plugin\marketplace.json')) { Ok 'HyperFrames 미리 받기 완료' } else { Bad 'HyperFrames 미리 받기 안 됨 - 01-prereq 를 다시 실행' }
    if (Test-Path (Join-Path $kalsHome 'gptaku_plugins\plugins\insane-design\.claude-plugin\plugin.json')) { Ok 'insane-design 미리 받기 완료' } else { Bad 'insane-design 미리 받기 안 됨 - 01-prereq 를 다시 실행' }

    Section '4. Claude Code (수업 중 설치)'
    $claudeExe = Join-Path $env:USERPROFILE '.local\bin\claude.exe'
    $claudeCmd = Get-Command claude -ErrorAction SilentlyContinue
    if (Test-Path $claudeExe) { Ok ((& $claudeExe --version) | Select-Object -First 1) }
    elseif ($claudeCmd) { Ok ((& $claudeCmd.Source --version) | Select-Object -First 1) }
    else { Info '아직 없음 - 02-install-claude 에서 설치' }
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if ($userPath -and $userPath -like '*\.local\bin*') { Ok '사용자 PATH에 .local\bin 있음' } else { Info '사용자 PATH에 .local\bin 없음 - 02 실행' }
    $pluginsJson = Join-Path $env:USERPROFILE '.claude\plugins\installed_plugins.json'
    foreach ($plugin in @('insane-design@gptaku-plugins', 'hyperframes@hyperframes')) {
        if ((Test-Path $pluginsJson) -and (Select-String -Path $pluginsJson -SimpleMatch "`"$plugin`"" -Quiet)) { Ok "플러그인 $plugin" } else { Info "플러그인 $plugin 아직 없음 - 03-skills" }
    }
    $claudeJson = Join-Path $env:USERPROFILE '.claude.json'
    if ((Test-Path $claudeJson) -and (Select-String -Path $claudeJson -SimpleMatch '"rea"' -Quiet)) { Ok 'REA MCP 연결됨' } else { Info 'REA 아직 없음 - 03-skills' }

    Section '5. 잘못된 연결 설정 검사'
    $settings = Join-Path $env:USERPROFILE '.claude\settings.json'
    if ((Test-Path $settings) -and (Select-String -Path $settings -Pattern '"ANTHROPIC_(BASE_URL|AUTH_TOKEN|API_KEY)"' -Quiet)) {
        Bad 'settings.json 에 연결 주소나 키가 박혀 있습니다 (setup-claude 를 눌렀을 가능성) - 99-restore 실행'
    } else { Ok '전역 설정 깨끗함' }
    $gatewayVars = @('ANTHROPIC_BASE_URL', 'ANTHROPIC_AUTH_TOKEN', 'ANTHROPIC_API_KEY')
    $persisted = $gatewayVars | Where-Object { [Environment]::GetEnvironmentVariable($_, 'User') }
    if ($persisted) { Bad "사용자 환경변수에 $($persisted -join ', ') 가 영구 저장되어 있습니다 - 99-restore 실행" } else { Ok '사용자 환경변수 깨끗함' }
    $inWindow = $gatewayVars | Where-Object { [Environment]::GetEnvironmentVariable($_, 'Process') }
    if ($inWindow) { Warn "이 창에 $($inWindow -join ', ') 가 들어 있습니다 - Orca를 완전히 종료한 뒤 다시 여세요" } else { Ok '이 창의 환경변수 깨끗함' }

    Write-Host ''
    Write-Host "결과: 실패 $script:kalsFails 개, 주의 $script:kalsWarns 개"
    if ($script:kalsFails -eq 0) { Write-Host '수업 준비 완료입니다.' -ForegroundColor Green }
    else { Write-Host '[XX] 항목을 고친 뒤 다시 실행해 주세요. 모르겠으면 이 화면을 캡처해 강사에게 보내 주세요.' -ForegroundColor Yellow }
}

Invoke-KalsDoctor
