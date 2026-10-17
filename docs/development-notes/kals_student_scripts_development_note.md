# docs/development-notes/kals_student_scripts_development_note.md


## KALS 특강 수강생 설치 스크립트 제작


### 날짜와 유형
2026-10-17에 작업했고 유형은 기능 추가입니다. KALS AI 강사반 Claude Code 특강에서 수강생이 명령 한 줄로 실행할 설치 스크립트를 macOS용 bash와 Windows용 PowerShell로 한 쌍씩, 모두 일곱 쌍(열네 개) 만들었습니다. 수업 전에 집에서 돌리는 사전 설치부터 Claude Code 설치, 플러그인 설치, 무료 모델 연결 실행기, 실습 폴더, 상태 점검, 연결 설정 되돌리기까지 수업의 설치 단계를 모두 다룹니다.


### 변경 사항
mac 폴더와 win 폴더에 00부터 05까지와 99, 모두 열네 개의 스크립트를 새로 추가하였고, 저장소 첫 화면에 실행 명령과 스크립트별로 바뀌는 파일을 정리한 README를 두었습니다. 04는 kals-free 명령을 설치해 freellmapi 통합 키를 암호화해 안전하게 보관하고, 그 세션에만 연결 변수를 넣습니다. 실행 주소는 강사가 정한 공개 저장소 mgm-biik/kals-claude-class의 원본 파일 주소로 넣어 두었습니다.


### 이유
강사가 수업 흐름을 명세로 정리하며 설치와 환경변수 설정을 스크립트로 묶어 달라고 요청했고, 배포는 공개 GitHub 저장소로 정했습니다. Claude Code 공식 설치기가 PATH를 넣지 않는 문제, Windows에서 플러그인 설치에 Git이 필요한 문제, Groq이 16384토큰을 넘는 출력을 거절하는 문제를 스크립트가 대신 처리하게 했습니다. 수백 MB인 플러그인 원본은 집에서 받게 해 수강생 여덟 명이 함께 쓰는 현장 와이파이를 아껴 주었습니다.


### 기술적 결정
HyperFrames는 스킬 폴더만 골라 받아 338MB를 32MB로 줄였고, gptaku는 insane-design 하위 저장소만 채워 703MB 복제를 피했습니다. Windows 스크립트는 한 줄 실행에서 창을 닫는 exit를 쓰지 않고, BOM이 iex를 깨므로 BOM 표시 없이 저장했습니다. PATH는 레지스트리에서 원래 형식 그대로 읽고 써서 항목 하나일 때 경로가 붙어 버리는 문제를 미리 막았고, 플러그인을 받을 때 줄바꿈 변환을 껐습니다.


## 기록


### 변경 파일
새로 만든 파일은 mac 폴더의 00-doctor.sh, 01-prereq.sh, 02-install-claude.sh, 03-skills.sh, 04-free.sh, 05-practice.sh, 99-restore.sh와 win 폴더의 같은 이름의 ps1 일곱 개, README.md, 이 개발일지입니다. 기존 파일을 고친 것은 하나도 없습니다. 수업 자료 저장소에 있는 수업 명세서는 이 저장소 밖에 있어 따로 갱신했습니다.


### 관련 커밋
abb31fd Add KALS class install scripts for macOS and Windows 커밋에 스크립트 열네 개와 README, 이 일지가 들어갔습니다. 강사가 정한 공개 저장소 mgm-biik/kals-claude-class의 main 브랜치로 올리며, 커밋 작성자는 강사가 고른 대로 git 전역 설정을 그대로 썼습니다. 메시지 끝에는 공동 작성자 표기를 붙였습니다. 이 절에 해시를 적은 것은 바로 그다음의 커밋입니다.


### 검증
macOS 스크립트는 홈 폴더를 임시 폴더로 바꿔 01, 02, 03, 05, 00, 99 순서로 실제 실행해 모두 통과했고, kals-free는 가상 터미널로 키 거절, 첫 저장, 재실행, 키 초기화를 확인했습니다. Windows 스크립트는 실기 시험을 못 해 문법 검사와 PSScriptAnalyzer의 PowerShell 5.1 호환 검사를 통과시켰습니다. Codex와 독립 검토자가 찾은 PATH 손상 등 결함은 다 고친 뒤 다시 검사해 통과했습니다.
