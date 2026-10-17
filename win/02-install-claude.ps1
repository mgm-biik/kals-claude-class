# KALS class, step 3 (Windows): install Claude Code CLI and put it on the user PATH.
# The official installer only prints a PATH warning, so this script adds %USERPROFILE%\.local\bin.
# Usage (PowerShell): irm <raw url>/win/02-install-claude.ps1 | iex
# Written for Windows PowerShell 5.1. Never call `exit`: under `irm | iex` it would close the window.

function Invoke-KalsInstallClaude {
    # 'Continue', not 'Stop': in PowerShell 5.1, native stderr under 'Stop' becomes a terminating error.
    $ErrorActionPreference = 'Continue'
    $binDir = Join-Path $env:USERPROFILE '.local\bin'
    $claudeExe = Join-Path $binDir 'claude.exe'
    $downloadsDir = Join-Path $env:USERPROFILE '.claude\downloads'
    $installCommand = '[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; irm https://claude.ai/install.ps1 | iex'

    function Say([string]$m) { Write-Host ''; Write-Host "==> $m" -ForegroundColor Cyan }
    function Ok([string]$m) { Write-Host "  [OK] $m" -ForegroundColor Green }
    function Warn([string]$m) { Write-Host "  [!!] $m" -ForegroundColor Yellow }
    function Fail([string]$m) { Write-Host "  [XX] $m" -ForegroundColor Red }

    function Find-Claude {
        if (Test-Path $claudeExe) { return $claudeExe }
        $cmd = Get-Command claude -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($cmd) { return $cmd.Source }
        return $null
    }

    # Add a folder to the user PATH without the two classic mistakes: a single existing entry being
    # treated as a string (which glues paths together), and REG_EXPAND_SZ turning into REG_SZ (which
    # freezes %USERPROFILE%-style entries). Returns $true when the PATH changed.
    function Add-UserPathEntry([string]$dir) {
        $key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment', $true)
        try {
            $raw = [string]$key.GetValue('Path', '', [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
            $entries = @($raw.Split(';') | Where-Object { $_ })
            $expanded = @($entries | ForEach-Object { [Environment]::ExpandEnvironmentVariables($_).TrimEnd('\') })
            if ($expanded -contains $dir.TrimEnd('\')) { return $false }
            $newPath = (@($entries) + $dir) -join ';'
            $key.SetValue('Path', $newPath, [Microsoft.Win32.RegistryValueKind]::ExpandString)
        }
        finally { $key.Close() }
        # Writing the registry directly does not notify other programs; a .NET user-variable write does.
        [Environment]::SetEnvironmentVariable('KALS_PATH_NOTIFY', '1', 'User')
        [Environment]::SetEnvironmentVariable('KALS_PATH_NOTIFY', $null, 'User')
        return $true
    }

    # Run the official installer in a child PowerShell, so an `exit` inside it cannot close this window.
    function Invoke-OfficialInstaller {
        powershell.exe -NoProfile -ExecutionPolicy Bypass -Command $installCommand
    }

    Say '1/3 Claude Code 설치'
    if (-not [Environment]::Is64BitProcess) { Fail '32비트 PowerShell입니다. (x86)이 붙지 않은 PowerShell을 여세요.'; return }
    # Only the native installer's claude.exe counts; an old npm-installed claude.ps1 is replaced.
    $found = $null
    if (Test-Path $claudeExe) { $found = $claudeExe }
    if ($found) { Ok "이미 설치됨: $((& $found --version) | Select-Object -First 1)" }
    else {
        Invoke-OfficialInstaller
        if (-not (Find-Claude)) {
            # Antivirus can lock a half-downloaded file; the documented fix is to clear downloads and retry.
            Warn '첫 설치가 실패해 내려받던 파일을 지우고 한 번 더 시도합니다.'
            if (Test-Path $downloadsDir) { Remove-Item $downloadsDir -Recurse -Force -ErrorAction SilentlyContinue }
            Invoke-OfficialInstaller
        }
        if (-not (Find-Claude) -and (Get-Command winget -ErrorAction SilentlyContinue)) {
            Warn '공식 설치가 또 실패해 winget 으로 설치합니다.'
            winget install --id Anthropic.ClaudeCode --exact --source winget --silent --accept-package-agreements --accept-source-agreements
            $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
        }
        $found = Find-Claude
        if (-not $found) { Fail '설치하지 못했습니다. 이 화면을 강사에게 보여 주세요.'; return }
        Ok "설치 완료: $((& $found --version) | Select-Object -First 1)"
    }

    Say '2/3 PATH 설정 (claude 를 어디서나 실행할 수 있게)'
    if (Add-UserPathEntry $binDir) { Ok "사용자 PATH에 $binDir 추가" } else { Ok '사용자 PATH에 이미 있음' }
    if (@($env:Path.Split(';')) -notcontains $binDir) { $env:Path = "$env:Path;$binDir" }

    Say '3/3 다음 할 일'
    Write-Host '  1. 30초쯤 기다렸다가 Orca에서 새 터미널 탭을 엽니다. 지금 탭은 바뀐 PATH를 늦게 알아챕니다.'
    Write-Host '  2. 새 탭에서  claude --version  을 쳐서 버전이 나오는지 봅니다.'
    Write-Host '  3. Orca 설정 - Agents 에서 Refresh 를 누릅니다.'
    Write-Host '  4. 같은 화면의 Agent Permissions 를 Manual 로 바꿉니다.'
    Write-Host '     (기본값은 Claude가 묻지 않고 파일을 고치게 둡니다. 연습 중에는 확인하며 쓰는 편이 안전합니다.)'
    Write-Host '  5. claude 를 실행해 유료 계정으로 로그인합니다.'
}

Invoke-KalsInstallClaude
