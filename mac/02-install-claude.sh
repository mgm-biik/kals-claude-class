#!/usr/bin/env bash
# KALS class, step 3 (macOS): install Claude Code CLI and put it on PATH.
# The official installer only prints a PATH warning, so this script adds ~/.local/bin to ~/.zshrc.
# Usage: curl -fsSL <raw url>/mac/02-install-claude.sh | bash
set -euo pipefail

readonly CLAUDE_INSTALL_URL="https://claude.ai/install.sh"
readonly CLAUDE_BIN="$HOME/.local/bin/claude"
readonly PATH_LINE='export PATH="$HOME/.local/bin:$PATH"'
readonly ZSHRC="$HOME/.zshrc"

say() { printf '\n==> %s\n' "$*"; }
ok() { printf '  [OK] %s\n' "$*"; }
die() { printf '  [XX] %s\n' "$*"; exit 1; }

say "1/3 Claude Code 설치"
if [ -x "$CLAUDE_BIN" ]; then
  ok "이미 설치됨: $("$CLAUDE_BIN" --version | head -1)"
else
  curl -fsSL "$CLAUDE_INSTALL_URL" | bash
  [ -x "$CLAUDE_BIN" ] || die "설치 파일을 찾지 못했습니다. 위 오류 화면을 강사에게 보여 주세요."
  ok "설치 완료: $("$CLAUDE_BIN" --version | head -1)"
fi

say "2/3 PATH 설정 (claude 를 어디서나 실행할 수 있게)"
if grep -qs '\.local/bin' "$ZSHRC"; then
  ok "$ZSHRC 에 이미 있음"
else
  printf '\n# Claude Code (KALS class)\n%s\n' "$PATH_LINE" >>"$ZSHRC"
  ok "$ZSHRC 에 추가"
fi

say "3/3 다음 할 일"
cat <<'EOF'
  1. Orca에서 새 터미널 탭을 엽니다. 지금 탭은 바뀐 PATH를 모릅니다.
  2. 새 탭에서  claude --version  을 쳐서 버전이 나오는지 봅니다.
  3. Orca 설정 → Agents 에서 Refresh 를 누릅니다.
  4. 같은 화면의 Agent Permissions 를 Manual 로 바꿉니다.
     (기본값은 Claude가 묻지 않고 파일을 고치게 둡니다. 연습 중에는 확인하며 쓰는 편이 안전합니다.)
  5. claude 를 실행해 유료 계정으로 로그인합니다.
EOF
