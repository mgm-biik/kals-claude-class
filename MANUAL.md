# 명령어 모음집 — 스크립트가 안 될 때

스크립트(`01`~`05`, `99`)가 실패하면 이 문서의 명령을 한 줄씩 직접 칩니다. 스크립트가 하는 일을 그대로 풀어 놓았습니다. 막힌 단계부터 시작하면 되고, 이미 된 단계는 건너뜁니다.

- **macOS**는 Orca의 터미널(zsh)에 칩니다.
- **Windows**는 Orca의 터미널에서 **PowerShell**에 칩니다. 줄 맨 앞에 `PS C:\...>`가 보이면 PowerShell이고, `C:\...>`만 보이면 명령 프롬프트(CMD)입니다.
- `freellmapi-여기에-통합키`처럼 "여기에"가 들어간 부분은 자기 값으로 바꿉니다.
- 명령을 친 뒤 빨간 오류가 나오면 맨 아래 [자주 나는 오류](#자주-나는-오류) 표를 먼저 봅니다.


## 모두 막혔을 때의 비상 경로

1. 옆 사람 노트북으로 같이 따라 하고, 내 노트북은 수업 뒤에 이 문서로 마저 합니다.
2. Claude Code 자체는 **Claude 데스크톱 앱의 Code 탭**에서도 쓸 수 있습니다(유료 요금제 로그인). 다만 무료 모델 연결(6단계)은 데스크톱 앱에서 되지 않고 터미널에서만 됩니다.


## 1. 사전 준비 (스크립트 `01`)

### macOS

macOS 터미널(zsh)은 `#` 뒤를 주석으로 처리하지 않으므로, 이 문서의 macOS 명령 블록에는 주석을 넣지 않았습니다. 블록을 그대로 복사해 붙이면 됩니다.

먼저 Homebrew(맥용 프로그램 설치 도구)를 설치합니다. 이미 있으면 건너뜁니다. 비밀번호를 물으면 맥 로그인 비밀번호를 칩니다(입력해도 화면에 안 보입니다).

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

설치가 끝나면 brew를 이 창과 앞으로 열 창에서 쓸 수 있게 합니다. 아래는 Apple 칩 맥 기준이고, 인텔 맥이면 `/opt/homebrew`를 `/usr/local`로 바꿉니다.

```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

Node.js, FFmpeg, Python을 설치하고 버전을 확인합니다. Node는 22.19 이상(23과 25는 안 됨), Python은 3.11 이상이어야 합니다.

```bash
brew install node ffmpeg python
node --version
python3 --version
ffmpeg -version
git --version
```

### Windows (PowerShell)

```powershell
# Git, Node.js, FFmpeg, Python. 관리자 권한 창이 뜨면 '예'를 누릅니다.
winget install --id Git.Git -e --source winget
winget install --id OpenJS.NodeJS.LTS -e --source winget
winget install --id Gyan.FFmpeg -e --source winget
winget install --id Python.Python.3.12 -e --source winget
```

여기서 **PowerShell 창(Orca 탭)을 닫고 새로 엽니다.** 새로 깐 프로그램은 새 창에서만 보입니다.

```powershell
# npx 같은 명령이 막히지 않게, 이 사용자만 실행 정책을 바꿉니다.
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force

# insane-design 은 python3 이라는 이름으로 Python 을 부릅니다. 같은 파일을 python3.exe 로 복사해 둡니다.
# (Python 을 winget 이 아닌 다른 방법으로 다른 폴더에 설치했다면 이 줄이 실패합니다. 강사에게 알려 주세요.)
Copy-Item "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe" "$env:LOCALAPPDATA\Programs\Python\Python312\python3.exe"

# 긴 경로 허용
git config --global core.longpaths true

# 버전 확인
node --version
python3 --version
git --version
ffmpeg -version
```

`winget` 자체가 없다는 오류가 나면 Microsoft Store에서 **앱 설치 관리자(App Installer)**를 설치합니다. 그래도 안 되면 아래 공식 사이트에서 설치 파일을 받습니다(강사 USB에도 있습니다).

- Git: git-scm.com
- Node.js LTS: nodejs.org
- Python 3.12: python.org — 설치 첫 화면에서 **Add python.exe to PATH**를 꼭 체크합니다.
- FFmpeg는 직접 설치가 까다로우니 강사에게 알려 주세요.

### 수업용 플러그인 미리 받기 (두 운영체제 공통)

수업 중 와이파이를 아끼려고 집에서 받아 두는 단계입니다. 실패해도 수업은 진행되고, 4단계에서 인터넷으로 받으면 됩니다(수백 MB라 오래 걸립니다).

macOS:

```bash
mkdir -p ~/.kals
git clone --depth 1 --filter=blob:none --sparse https://github.com/heygen-com/hyperframes ~/.kals/hyperframes
git -C ~/.kals/hyperframes sparse-checkout set skills .claude-plugin
git clone --depth 1 https://github.com/fivetaku/gptaku_plugins ~/.kals/gptaku_plugins
git -C ~/.kals/gptaku_plugins submodule update --init --depth 1 plugins/insane-design
npx --yes hyperframes@latest browser ensure
```

Windows (PowerShell). `-c core.autocrlf=false`는 줄바꿈이 Windows식으로 바뀌어 플러그인이 깨지는 것을 막습니다.

```powershell
New-Item -ItemType Directory -Force "$HOME\.kals"
git -c core.autocrlf=false clone --depth 1 --filter=blob:none --sparse https://github.com/heygen-com/hyperframes "$HOME\.kals\hyperframes"
git -c core.autocrlf=false -C "$HOME\.kals\hyperframes" sparse-checkout set skills .claude-plugin
git -c core.autocrlf=false clone --depth 1 https://github.com/fivetaku/gptaku_plugins "$HOME\.kals\gptaku_plugins"
git -c core.autocrlf=false -C "$HOME\.kals\gptaku_plugins" submodule update --init --depth 1 plugins/insane-design
npx.cmd --yes hyperframes@latest browser ensure
```


## 2. Claude Code 설치 (스크립트 `02`)

### macOS

설치기는 PATH를 넣어 주지 않으므로 두 번째 줄에서 직접 넣습니다.

```bash
curl -fsSL https://claude.ai/install.sh | bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
claude --version
```

### Windows (PowerShell)

```powershell
irm https://claude.ai/install.ps1 | iex
```

설치기는 PATH를 넣어 주지 않습니다. 아래 순서로 **화면에서** 넣는 것이 가장 안전합니다. `setx PATH ...` 명령은 기존 PATH를 망가뜨릴 수 있어 쓰지 않습니다.

1. 시작 메뉴에서 **"계정의 환경 변수 편집"**을 검색해 엽니다.
2. 위쪽 "사용자 변수"에서 **Path**를 고르고 **편집**을 누릅니다.
3. **새로 만들기**를 누르고 `%USERPROFILE%\.local\bin`을 넣은 뒤 확인을 누릅니다.
4. 30초쯤 뒤 Orca에서 **새 터미널 탭**을 열고 `claude --version`을 칩니다.

지금 창에서만 당장 쓰려면 다음 한 줄로도 됩니다(창을 닫으면 사라집니다).

```powershell
$env:Path += ";$env:USERPROFILE\.local\bin"
```

설치가 실패하면 차례로 시도합니다.

```powershell
# 1) 백신이 내려받던 파일을 잠근 경우: 받던 파일을 지우고 다시 설치
Remove-Item -Recurse -Force "$env:USERPROFILE\.claude\downloads" -ErrorAction SilentlyContinue
irm https://claude.ai/install.ps1 | iex

# 2) 그래도 안 되면 winget 으로 설치
winget install --id Anthropic.ClaudeCode -e --source winget
```

CMD 창에서는 이 명령을 씁니다: `curl -fsSL https://claude.ai/install.cmd -o install.cmd && install.cmd && del install.cmd`

### 설치 뒤 Orca 설정 (두 운영체제 공통)

- Orca 설정 › **Agents** › **Refresh**를 누릅니다.
- 같은 화면 **Agent Permissions**를 **Manual**로 바꿉니다. 기본값은 Claude가 묻지 않고 파일을 고치게 둡니다.


## 3. 로그인

```text
claude
```

브라우저가 열리면 유료 계정을 고릅니다. 브라우저가 안 열리면 터미널에서 `c`를 눌러 주소를 복사해 브라우저에 붙여넣습니다. 그래도 안 되면 Claude Code를 닫고 `claude auth login`을 칩니다. 로그인 뒤 Claude Code 안에서 `/status`를 쳐서 로그인 방식이 구독인지 확인합니다.


## 4. 스킬 설치 (스크립트 `03`)

Claude Code를 닫은 상태(`/exit`)에서 터미널에 칩니다. 1단계에서 미리 받아 둔 폴더가 없으면 `~/.kals/gptaku_plugins` 대신 `fivetaku/gptaku_plugins`를, `~/.kals/hyperframes` 대신 `heygen-com/hyperframes`를 씁니다(인터넷에서 받아 오래 걸립니다).

macOS:

```bash
claude plugin marketplace add ~/.kals/gptaku_plugins
claude plugin install insane-design@gptaku-plugins
claude plugin marketplace add ~/.kals/hyperframes
claude plugin install hyperframes@hyperframes
npx --yes rea-agents@latest setup --client claude_code --yes
```

Windows (PowerShell):

```powershell
$env:CLAUDE_CODE_PLUGIN_GIT_TIMEOUT_MS = "300000"   # 인터넷에서 받을 때 시간 초과 방지
claude plugin marketplace add "$HOME\.kals\gptaku_plugins"   # 없으면: fivetaku/gptaku_plugins
claude plugin install insane-design@gptaku-plugins
claude plugin marketplace add "$HOME\.kals\hyperframes"      # 없으면: heygen-com/hyperframes
claude plugin install hyperframes@hyperframes
npx.cmd --yes rea-agents@latest setup --client claude_code --yes
```

Claude Code 안에서 설치해도 됩니다. 입력창에 아래를 하나씩 칩니다.

```text
/plugin marketplace add fivetaku/gptaku_plugins
/plugin install insane-design@gptaku-plugins
/plugin marketplace add heygen-com/hyperframes
/plugin install hyperframes@hyperframes
```

설치 뒤에는 Claude Code를 닫았다가 다시 열고, `/plugin`과 `/mcp`로 insane-design, hyperframes, rea가 보이는지 확인합니다.


## 5. 무료 모델 연결 (스크립트 `04`)

freellmapi 앱을 켜고, Claude Code 카드의 **수동 연결**에서 `BASE_URL`과 `API_KEY`(통합 키)를 확인합니다. 주소가 `http://127.0.0.1:31415`가 아니면 아래 주소를 앱에 나온 값으로 바꿉니다. 아래 설정은 **그 창에서만** 살아 있어서, 창을 닫으면 원래 유료 요금제로 돌아갑니다.

macOS:

```bash
export ANTHROPIC_BASE_URL=http://127.0.0.1:31415
export ANTHROPIC_AUTH_TOKEN=freellmapi-여기에-통합키
export CLAUDE_CODE_MAX_OUTPUT_TOKENS=16000
export GPTAKU_ROUTER=off
unset ANTHROPIC_API_KEY
claude
```

Windows (PowerShell):

```powershell
$env:ANTHROPIC_BASE_URL = "http://127.0.0.1:31415"
$env:ANTHROPIC_AUTH_TOKEN = "freellmapi-여기에-통합키"
$env:CLAUDE_CODE_MAX_OUTPUT_TOKENS = "16000"
$env:GPTAKU_ROUTER = "off"
Remove-Item Env:ANTHROPIC_API_KEY -ErrorAction SilentlyContinue
claude
```

각 줄의 뜻은 다음과 같습니다.

- **`CLAUDE_CODE_MAX_OUTPUT_TOKENS=16000`:** Groq이 16,384토큰을 넘는 출력 요청을 거절하기 때문에 넣습니다. 이 줄이 없으면 Groq 키만 있는 사람은 Claude Code가 작동하지 않습니다.
- **`GPTAKU_ROUTER=off`:** insane-design이 프롬프트마다 덧붙이는 안내를 끕니다. 무료 모델이 그 안내에 헷갈리지 않게 하려는 것입니다.

연결되면 Claude Code 안에서 `/status`를 쳐서 주소가 `127.0.0.1:31415`인지 확인합니다.

**하지 말 것**

- **앱의 `npx freellmapi setup-claude`:** 모든 Claude Code 세션을 무료 모델로 바꿔 버립니다.
- **`setx` 명령:** 영구 저장되어 freellmapi를 끈 날 Claude Code가 아예 안 됩니다.
- **키를 남이 볼 수 있는 곳에 남기기:** 통합 키는 터미널 기록에 남으므로 공용 컴퓨터에서는 쓰지 않습니다.


## 6. 실습 폴더 (스크립트 `05`)

macOS:

```bash
mkdir -p ~/kals-practice/out && cd ~/kals-practice && claude
```

Windows (PowerShell):

```powershell
New-Item -ItemType Directory -Force "$HOME\kals-practice\out"; cd "$HOME\kals-practice"; claude
```

Claude Code가 열리면 아래 명세에서 이름과 소개만 내 것으로 바꿔 **한 번에** 붙여넣습니다.

```text
목표: 내 이름과 한 줄 소개가 나오는 10초 타이틀 카드 영상을 HyperFrames로 만든다.
결과물: 1920x1080, 30fps, 10초 MP4 한 개. out/title.mp4 로 저장한다.
재료: 이름 "홍길동", 소개 "AI로 일하는 법을 배우는 중", 배경 남색 #0B1D35, 강조색 코랄 #FF5A4E.
제약: 이름이 먼저 나오고 1초 뒤 소개가 나온다. 한글이 깨지거나 화면 밖으로 나가지 않는다.
완료 기준: HyperFrames 렌더로 out/title.mp4 가 만들어지고 끝까지 재생된다.
하지 말 것: 외부 이미지나 음악을 내려받지 않는다. 명세에 없는 장면을 더하지 않는다.
```

렌더가 실패하면 터미널에서 `npx hyperframes doctor`(Windows는 `npx.cmd hyperframes doctor`)로 원인을 봅니다. 디스크 여유가 2GB보다 적으면 실패합니다.


## 7. 상태 점검 (스크립트 `00`)

| 확인할 것 | macOS | Windows (PowerShell) |
|---|---|---|
| Claude Code | `claude --version` | `claude --version` |
| Node.js (22.19 이상) | `node --version` | `node --version` |
| Python (3.11 이상) | `python3 --version` | `python3 --version` |
| Git | `git --version` | `git --version` |
| FFmpeg | `ffmpeg -version` | `ffmpeg -version` |
| freellmapi 켜짐 | `curl http://127.0.0.1:31415/health` | `curl.exe http://127.0.0.1:31415/health` |
| 플러그인 | `claude plugin list` | `claude plugin list` |
| REA 연결 | `claude mcp list` | `claude mcp list` |

Windows PowerShell 5.1에서 그냥 `curl`이라고 치면 다른 명령이 실행되므로 `curl.exe`라고 칩니다.


## 8. 되돌리기 (스크립트 `99`)

- **무료 연결을 끄려면:** 그 터미널 창을 닫으면 끝납니다.
- **`setup-claude`를 실수로 눌렀다면:** 전역 설정 파일을 열어 `env` 안의 `ANTHROPIC_BASE_URL`, `ANTHROPIC_AUTH_TOKEN`, `ANTHROPIC_MODEL`, `ANTHROPIC_DEFAULT_..._MODEL` 줄을 지우고 저장합니다. 고치기 전에 파일을 복사해 두세요. freellmapi는 원본을 `settings.json.backup-<시각>`으로 남겨 두니 그 파일로 되돌려도 됩니다.
  - macOS: `open -e ~/.claude/settings.json`
  - Windows: `notepad "$HOME\.claude\settings.json"`
- **Windows에서 `setx`로 영구 저장했다면:**

```powershell
[Environment]::SetEnvironmentVariable("ANTHROPIC_BASE_URL", $null, "User")
[Environment]::SetEnvironmentVariable("ANTHROPIC_AUTH_TOKEN", $null, "User")
[Environment]::SetEnvironmentVariable("ANTHROPIC_API_KEY", $null, "User")
```

그다음 Orca를 트레이 아이콘까지 완전히 종료한 뒤 다시 엽니다.


## 자주 나는 오류

| 화면에 보이는 것 | 원인 | 해결 |
|---|---|---|
| `'irm' is not recognized` / `'irm'은(는) ... 아닙니다` | CMD 창에 PowerShell 명령을 침 | PowerShell 탭을 열고 다시 칩니다 |
| `The token '&&' is not a valid statement separator` | PowerShell 창에 CMD 명령을 침 | PowerShell용 명령을 쓰거나 CMD 탭을 엽니다 |
| `claude: command not found` / `'claude' 용어가 ... 인식되지 않습니다` | PATH에 `~/.local/bin`이 없거나 옛 창 | 2단계의 PATH 설정 후 **새 탭**을 엽니다 |
| `npx.ps1 cannot be loaded because running scripts is disabled` | Windows 실행 정책 | `npx` 대신 `npx.cmd`를 쓰거나 1단계의 `Set-ExecutionPolicy` 실행 |
| `python3`을 치면 Microsoft Store가 열림 | Store 바로가기가 먼저 잡힘 | 1단계의 `python3.exe` 복사를 하고, 설정 › 앱 › 고급 앱 설정 › 앱 실행 별칭에서 python 두 개를 끕니다 |
| `$'\r': command not found` | 플러그인이 Windows식 줄바꿈으로 받아짐 | `$HOME\.kals` 폴더를 지우고 1단계를 `-c core.autocrlf=false`로 다시 |
| Groq 가입에서 `signup_blocked` | 노트북·브라우저가 차단으로 분류됨 | 다시 누르지 말고 휴대폰 LTE로 가입한 뒤, 노트북에서는 로그인만 |
| `max_tokens must be less than or equal to 16384` | Claude Code 출력 요청이 Groq 한도 초과 | 5단계의 `CLAUDE_CODE_MAX_OUTPUT_TOKENS=16000` |
| `Invalid API key` / `401` (freellmapi) | 통합 키 오타 | 앱에서 통합 키를 다시 복사해 붙여넣기 |
| `Connection refused` / `Unable to connect` | freellmapi 앱이 꺼짐 | 앱을 켜고 7단계의 `health` 확인 |
| 무료 모델이 엉뚱한 답을 함 | 작은 모델의 한계 | 명세를 더 짧고 분명하게, 또는 유료 세션(`claude`)으로 |
