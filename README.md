# KALS Claude Code 특강 설치 스크립트

KALS AI 강사반 Claude Code 특강(2026-10-17)에서 쓰는 설치·연결 스크립트입니다. 명령 한 줄로 실행하고, 각 스크립트가 무엇을 바꾸는지 아래에 모두 적었습니다. API 키 같은 비밀값은 저장소 어디에도 없습니다.

- macOS는 **터미널**(Orca의 터미널 탭)에 붙여넣습니다.
- Windows는 **PowerShell**(Orca의 터미널 탭)에 붙여넣습니다. 명령 프롬프트(CMD)가 아닙니다.
- **스크립트가 실패하면** [명령어 모음집(MANUAL.md)](MANUAL.md)의 명령을 단계별로 직접 칩니다. 자주 나는 오류와 해결법도 그 문서 끝에 있습니다.


## 순서

| 언제 | 순서 | 하는 일 |
|---|---|---|
| 수업 전, 집에서 | 01 → 00 | 개발 도구 설치, 수업용 플러그인 미리 받기, 상태 점검 |
| 수업 중 | 02 → 로그인 → 03 → 05 → 04 | Claude Code 설치, 플러그인 설치, 실습 폴더, 무료 모델 연결 |
| 문제가 생겼을 때 | 00, 99 | 상태 점검, 연결 설정 되돌리기 |


## 명령

**macOS**

```bash
curl -fsSL https://raw.githubusercontent.com/mgm-biik/kals-claude-class/main/mac/01-prereq.sh | bash
curl -fsSL https://raw.githubusercontent.com/mgm-biik/kals-claude-class/main/mac/00-doctor.sh | bash
curl -fsSL https://raw.githubusercontent.com/mgm-biik/kals-claude-class/main/mac/02-install-claude.sh | bash
curl -fsSL https://raw.githubusercontent.com/mgm-biik/kals-claude-class/main/mac/03-skills.sh | bash
curl -fsSL https://raw.githubusercontent.com/mgm-biik/kals-claude-class/main/mac/05-practice.sh | bash
curl -fsSL https://raw.githubusercontent.com/mgm-biik/kals-claude-class/main/mac/04-free.sh | bash
curl -fsSL https://raw.githubusercontent.com/mgm-biik/kals-claude-class/main/mac/99-restore.sh | bash
```

**Windows (PowerShell)**

```powershell
irm https://raw.githubusercontent.com/mgm-biik/kals-claude-class/main/win/01-prereq.ps1 | iex
irm https://raw.githubusercontent.com/mgm-biik/kals-claude-class/main/win/00-doctor.ps1 | iex
irm https://raw.githubusercontent.com/mgm-biik/kals-claude-class/main/win/02-install-claude.ps1 | iex
irm https://raw.githubusercontent.com/mgm-biik/kals-claude-class/main/win/03-skills.ps1 | iex
irm https://raw.githubusercontent.com/mgm-biik/kals-claude-class/main/win/05-practice.ps1 | iex
irm https://raw.githubusercontent.com/mgm-biik/kals-claude-class/main/win/04-free.ps1 | iex
irm https://raw.githubusercontent.com/mgm-biik/kals-claude-class/main/win/99-restore.ps1 | iex
```


## 스크립트별로 바꾸는 것

| 스크립트 | 설치하거나 바꾸는 것 |
|---|---|
| 00-doctor | 아무것도 바꾸지 않습니다. 점검만 합니다. |
| 01-prereq | macOS는 Homebrew와 Node.js, FFmpeg, Python을 설치합니다. Windows는 winget으로 Git, Node.js LTS, FFmpeg, Python 3.12를 설치하고, PowerShell 실행 정책을 이 사용자만 RemoteSigned로 바꿉니다. 두 운영체제 모두 HyperFrames와 insane-design 원본을 `~/.kals`에 받아 둡니다. |
| 02-install-claude | Claude Code 공식 설치 명령을 실행하고, `~/.local/bin`을 PATH에 추가합니다(macOS는 `~/.zshrc`, Windows는 사용자 PATH). |
| 03-skills | Claude Code에 insane-design, HyperFrames 플러그인을 설치하고, REA를 MCP 서버로 연결합니다(`~/.claude.json`). |
| 04-free | `kals-free` 명령을 만들고, freellmapi 통합 키를 macOS 키체인이나 Windows 사용자 전용 암호화 파일에 저장합니다. 연결 설정은 `kals-free`로 연 그 창에만 들어갑니다. |
| 05-practice | 홈 폴더에 `kals-practice` 실습 폴더와 명세 양식을 만듭니다. 이미 있는 파일은 덮어쓰지 않습니다. |
| 99-restore | Claude Code 전역 설정에 박힌 연결 주소와 키를 백업한 뒤 지우고, 저장한 키를 지울지 묻습니다. 플러그인은 그대로 둡니다. |


## 꼭 알아 둘 것

- **freellmapi 앱의 "빠른 시작"에 있는 `npx freellmapi setup-claude`는 실행하지 마세요.** 모든 Claude Code 세션이 무료 모델로 바뀝니다. 실수로 실행했다면 `99-restore`로 되돌립니다.
- **무료 모델 연결은 터미널에서만 됩니다.** Claude 데스크톱 앱의 Code 탭은 이 설정을 읽지 않습니다.
- **무료 모델은 연습용입니다.** 개인 정보나 회사 자료를 넣지 마세요. Anthropic은 Claude Code를 Claude가 아닌 모델에 연결하는 것을 지원하지 않습니다.
- **Groq은 긴 출력을 거절합니다.** 그래서 `kals-free`는 출력 길이를 16,000토큰으로 제한합니다. Cloudflare 모델은 Claude Code 요청을 가끔 거절하는데, freellmapi가 다른 회사로 자동으로 넘깁니다.
- **HyperFrames는 익명 사용 통계를 보냅니다.** 끄려면 `npx hyperframes telemetry disable`을 실행합니다.
- **Windows 사용자 폴더 이름에 한글이나 공백이 있으면** 일부 플러그인 기능이 오작동합니다. `00-doctor`가 알려 주니 강사에게 말해 주세요.


## 지우는 방법

Claude Code 안에서 지우거나, 터미널에서 아래를 실행합니다. HyperFrames 플러그인은 `~/.kals/hyperframes`를 직접 읽으므로, 그 폴더는 플러그인을 지운 뒤에 지웁니다.

```bash
claude plugin uninstall hyperframes@hyperframes
claude plugin uninstall insane-design@gptaku-plugins
npx rea-agents uninstall
```

그다음 `~/.kals` 폴더와 `kals-free` 명령(macOS `~/.local/bin/kals-free`, Windows `%USERPROFILE%\.local\bin\kals-free.cmd`)을 지우면 됩니다.


## 비익 구성원용 claude-free

비익 온보딩 안내서는 `kals-free` 대신 같은 일을 하는 `claude-free` 명령을 씁니다. 동작은 `04-free`와 똑같고 명령 이름과 키를 저장하는 자리만 다르므로, 두 명령을 한 컴퓨터에 함께 둘 수 있습니다. freellmapi 앱을 켜고 키를 넣은 뒤에 실행합니다.

**macOS**

```bash
curl -fsSL https://raw.githubusercontent.com/mgm-biik/kals-claude-class/main/biik/mac/claude-free.sh | bash
```

**Windows (PowerShell)**

```powershell
irm https://raw.githubusercontent.com/mgm-biik/kals-claude-class/main/biik/win/claude-free.ps1 | iex
```

| 운영체제 | 설치하거나 바꾸는 것 |
|---|---|
| macOS | `~/.local/bin/claude-free` 명령을 만들고, 통합 키를 키체인의 `freellmapi-unified-key` 항목에 저장합니다. `~/.zshrc`에 같은 이름의 alias가 있으면 그 alias가 먼저 실행된다고 알려 줍니다. |
| Windows | `%USERPROFILE%\.local\bin\claude-free.cmd`와 `%USERPROFILE%\.biik\claude-free.ps1`을 만들고, 통합 키를 `%USERPROFILE%\.biik\freellmapi.key`에 이 Windows 사용자만 풀 수 있게 암호화해 저장합니다. |

지울 때는 macOS에서 `rm ~/.local/bin/claude-free`와 `security delete-generic-password -s freellmapi-unified-key -a "$USER"`를 실행합니다. Windows에서는 위 표의 세 파일을 지웁니다.
