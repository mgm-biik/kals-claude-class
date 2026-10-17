#!/usr/bin/env bash
# KALS class, step 7 (macOS): create the practice folder with a CLAUDE.md, the single-turn spec
# template and a worked example for a HyperFrames title card. Existing files are never overwritten.
# Usage: curl -fsSL <raw url>/mac/05-practice.sh | bash
set -euo pipefail

readonly PRACTICE_DIR="$HOME/kals-practice"

write_once() {
  local path="$1"
  if [ -e "$path" ]; then echo "  [--] 이미 있어 건드리지 않음: $path"; cat >/dev/null; return; fi
  cat >"$path"
  echo "  [OK] 만듦: $path"
}

mkdir -p "$PRACTICE_DIR/out"

write_once "$PRACTICE_DIR/CLAUDE.md" <<'EOF'
# 실습 폴더 안내

이 폴더는 KALS 수업 실습용이다. 이 파일은 Claude Code가 세션을 시작할 때마다 자동으로 읽는다.

- 사용자가 준 명세를 그대로 따른다. 명세에 없는 기능은 더하지 않는다.
- 명세가 모호하면 만들기 전에 한 번만 묻는다.
- 결과물은 out 폴더에 저장한다.
- 명세의 완료 기준을 직접 확인한 뒤에 끝났다고 말한다.
EOF

write_once "$PRACTICE_DIR/명세_양식.md" <<'EOF'
목표: 무엇을 만드는가 (한 문장)
결과물: 파일 형식, 길이, 크기, 저장 위치
재료: 쓸 문구, 색, 이미지, 참고 자료
제약: 반드시 지킬 것
완료 기준: 끝났다고 판단하는 방법
하지 말 것: 피할 것
EOF

write_once "$PRACTICE_DIR/명세_예시.md" <<'EOF'
목표: 내 이름과 한 줄 소개가 나오는 10초 타이틀 카드 영상을 HyperFrames로 만든다.
결과물: 1920x1080, 30fps, 10초 MP4 한 개. out/title.mp4 로 저장한다.
재료: 이름 "홍길동", 소개 "AI로 일하는 법을 배우는 중", 배경 남색 #0B1D35, 강조색 코랄 #FF5A4E.
제약: 이름이 먼저 나오고 1초 뒤 소개가 나온다. 한글이 깨지거나 화면 밖으로 나가지 않는다.
완료 기준: HyperFrames 렌더로 out/title.mp4 가 만들어지고 끝까지 재생된다.
하지 말 것: 외부 이미지나 음악을 내려받지 않는다. 명세에 없는 장면을 더하지 않는다.
EOF

cat <<EOF

실습 폴더를 만들었습니다: $PRACTICE_DIR
  1. cd ~/kals-practice
  2. 명세_예시.md 를 열어 이름과 소개를 내 것으로 바꿉니다.
  3. claude 를 실행하고, 명세 전체를 한 번에 붙여넣습니다.
EOF
