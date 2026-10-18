# docs/development-notes/biik_claude_free_development_note.md


## 비익 구성원용 claude-free 스크립트 추가


### 날짜와 유형
2026-10-18에 작업했고 유형은 기능 추가입니다. 비익 온보딩 안내서가 무료 모델 연결 명령으로 kals-free 대신 claude-free를 쓰기로 해서, 같은 일을 하는 비익 전용 설치 스크립트를 macOS용 bash와 Windows용 PowerShell로 한 쌍 만들었습니다. 기존 KALS 스크립트 일곱 쌍은 한 글자도 바꾸지 않았고, 새 스크립트는 biik 폴더에만 두었습니다. 새 명령은 비익 온보딩 안내서 3-4절에서 설명해 둡니다.


### 변경 사항
biik/mac/claude-free.sh와 biik/win/claude-free.ps1을 새로 만들어 두었습니다. 둘 다 04-free를 바탕으로 명령 이름과 키를 저장하는 자리, 안내 문구 세 가지만 바꿨습니다. 또 macOS판에는 ~/.zshrc에 같은 이름의 alias가 있으면 알려 주는 경고 네 줄을 새로 더했습니다. README.md 끝에는 두 설치 명령과 바꾸는 파일, 지우는 방법을 적은 비익 구성원용 절을 새로 덧붙였습니다.


### 이유
사용자가 비익 안내서에서는 freellmapi와 Claude Code를 잇는 명령을 claude-free로 부르는 편이 낫다고 하며, 수업 때 쓴 이 공개 저장소에 비익 전용 스크립트를 올려 달라고 요청했습니다. 작성자의 컴퓨터에는 이미 같은 이름의 alias가 있었고, 그 alias는 키체인 항목 freellmapi-unified-key에서 통합 키를 꺼내 씁니다. 그래서 그 이름과 저장 방식을 이어받는 쪽이 사용자에게 덜 낯설다고 보았습니다.


### 기술적 결정
macOS판은 키체인 항목 이름을 기존 alias와 같은 freellmapi-unified-key로 맞춰, 이미 저장된 키를 다시 묻지 않고 쓰게 했습니다. Windows판은 키 폴더를 .kals 대신 .biik로 두어 두 명령이 서로 키를 지우지 않게 했습니다. 셸 alias는 설치된 명령보다 먼저 실행되므로, 설치 끝에 경고만 띄우고 사용자의 설정 파일은 고치지 않았습니다. GPTAKU_ROUTER를 끄는 줄은 해가 없어 두고 주석만 고쳤습니다.


## 기록


### 변경 파일
새 파일은 biik/mac/claude-free.sh, biik/win/claude-free.ps1, 그리고 이 개발일지까지 모두 세 개입니다. 고친 파일은 README.md 한 개이고 끝에 비익 구성원용 절만 덧붙였고 기존 절은 한 줄도 고치지 않았습니다. mac과 win 폴더의 기존 스크립트와 MANUAL.md, 기존 개발일지는 그대로 두었습니다. 시험에 쓴 가짜 서버와 대역 명령은 임시 폴더에만 두었고 저장소에는 전혀 넣지 않았습니다.


### 관련 커밋
a835c51 Add claude-free install scripts for Biik onboarding 커밋에 들어갔습니다. 사용자가 이 공개 저장소에 비익 전용 스크립트를 올려 달라고 요청해서, 두 스크립트와 README.md, 이 개발일지를 한 커밋에 묶어 main 브랜치에 올렸습니다. 이 해시를 적는 기록 커밋도 함께 원격 저장소에 푸시합니다. 푸시 전에 비밀값과 개인 경로가 없는지 다시 검사했습니다. 푸시한 뒤 raw 주소도 비교합니다.


### 검증
macOS판은 임시 홈 폴더와 가짜 freellmapi 서버, 키체인과 claude 대역 명령을 두고 실제 설치 방식대로 돌려 열세 항목을 모두 통과했습니다. 앱이 꺼진 경우, 접두어가 틀린 키, 거절된 키, 저장과 재사용, 키 다시 받기, alias 경고를 확인했으며, 키는 명령 인자에 한 번도 나타나지 않았습니다. shellcheck와 PowerShell 구문 분석도 통과했습니다. Windows판은 실제 Windows에서는 돌려 보지 못했습니다.
