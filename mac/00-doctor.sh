#!/usr/bin/env bash
# KALS class: read-only health check for macOS. It changes nothing on the machine.
# Usage: curl -fsSL <raw url>/mac/00-doctor.sh | bash
set -uo pipefail

readonly KALS_HOME="$HOME/.kals"
readonly FREELLMAPI_DEFAULT_PORT=31415
readonly FREELLMAPI_CONFIG="$HOME/Library/Application Support/FreeLLMAPI/config.json"
readonly MIN_MACOS_MAJOR=13
readonly MIN_FREE_GB=3
readonly MIN_NODE="22.0.0"
readonly MIN_PYTHON="3.11.0"

FAILS=0
WARNS=0
ok() { printf '  [OK] %s\n' "$*"; }
info() { printf '  [--] %s\n' "$*"; }
warn() { printf '  [!!] %s\n' "$*"; WARNS=$((WARNS + 1)); }
bad() { printf '  [XX] %s\n' "$*"; FAILS=$((FAILS + 1)); }
section() { printf '\n%s\n' "$*"; }

# True when version $1 >= version $2 (numeric, dot separated). macOS ships bash 3.2, so no sort -V.
version_ge() {
  awk -v a="$1" -v b="$2" 'BEGIN { split(a, x, "."); split(b, y, ".");
    for (i = 1; i <= 3; i++) { if (x[i] + 0 > y[i] + 0) exit 0; if (x[i] + 0 < y[i] + 0) exit 1 } exit 0 }'
}

# REA accepts Node 22.19+, 24.11+ or 26+; odd majors 23 and 25 are rejected.
node_ok_for_rea() {
  local v="$1" major="${1%%.*}"
  case "$major" in
    22) version_ge "$v" "22.19.0" ;;
    24) version_ge "$v" "24.11.0" ;;
    23 | 25) return 1 ;;
    *) [ "$major" -ge 26 ] ;;
  esac
}

freellmapi_port() {
  local port=""
  [ -f "$FREELLMAPI_CONFIG" ] && port="$(sed -nE 's/.*"port"[[:space:]]*:[[:space:]]*([0-9]+).*/\1/p' "$FREELLMAPI_CONFIG" | head -1)"
  echo "${port:-$FREELLMAPI_DEFAULT_PORT}"
}

find_claude() {
  if [ -x "$HOME/.local/bin/claude" ]; then echo "$HOME/.local/bin/claude"; return; fi
  command -v claude 2>/dev/null || true
}

section "1. 컴퓨터"
mac_version="$(sw_vers -productVersion)"
if [ "${mac_version%%.*}" -ge "$MIN_MACOS_MAJOR" ]; then ok "macOS $mac_version"; else bad "macOS $mac_version — 13 이상이어야 합니다"; fi
info "CPU $(uname -m)"
case "$HOME" in *" "*) warn "사용자 폴더 경로에 공백이 있습니다: $HOME — 강사에게 알려 주세요" ;; esac
if printf '%s' "$HOME" | LC_ALL=C grep -q '[^ -~]'; then warn "사용자 폴더 경로에 한글이 있습니다: $HOME — 강사에게 알려 주세요"; fi
free_gb="$(df -g "$HOME" | awk 'NR == 2 { print $4 }')"
if [ "${free_gb:-0}" -ge "$MIN_FREE_GB" ]; then ok "남은 디스크 ${free_gb}GB"; else bad "남은 디스크 ${free_gb}GB — ${MIN_FREE_GB}GB 이상 비워 주세요"; fi

section "2. 미리 설치할 앱"
if [ -d /Applications/Orca.app ] || [ -d "$HOME/Applications/Orca.app" ]; then ok "Orca 설치됨"; else bad "Orca가 없습니다 — onorca.dev 에서 설치"; fi
if [ -d /Applications/FreeLLMAPI.app ] || [ -d "$HOME/Applications/FreeLLMAPI.app" ]; then ok "freellmapi 설치됨"; else bad "freellmapi 앱이 없습니다"; fi
port="$(freellmapi_port)"
if curl -fsS --max-time 3 "http://127.0.0.1:$port/health" >/dev/null 2>&1; then ok "freellmapi 실행 중 (포트 $port)"; else warn "freellmapi가 꺼져 있습니다 (포트 $port) — 실습 전에 앱을 켜 주세요"; fi

section "3. 개발 도구 (01-prereq 가 설치)"
if command -v brew >/dev/null 2>&1 || [ -x /opt/homebrew/bin/brew ] || [ -x /usr/local/bin/brew ]; then ok "Homebrew"; else bad "Homebrew 없음"; fi
if xcode-select -p >/dev/null 2>&1 && git --version >/dev/null 2>&1; then ok "$(git --version)"; else bad "Git 없음 (Xcode 명령줄 도구 필요)"; fi
if command -v node >/dev/null 2>&1; then
  node_v="$(node --version | tr -d v)"
  if ! version_ge "$node_v" "$MIN_NODE"; then bad "Node.js $node_v — 22 이상이어야 합니다"
  elif ! node_ok_for_rea "$node_v"; then warn "Node.js $node_v — REA는 22.19+, 24.11+, 26+ 만 받습니다"
  else ok "Node.js $node_v"; fi
else bad "Node.js 없음"; fi
if command -v ffmpeg >/dev/null 2>&1; then ok "FFmpeg"; else bad "FFmpeg 없음 (영상 렌더에 필요)"; fi
if command -v python3 >/dev/null 2>&1; then
  py_v="$(python3 -c 'import sys; print("%d.%d.%d" % sys.version_info[:3])' 2>/dev/null || echo 0)"
  if version_ge "$py_v" "$MIN_PYTHON"; then ok "Python $py_v"; else bad "Python $py_v — 3.11 이상이어야 합니다"; fi
else bad "Python 없음"; fi
if [ -f "$KALS_HOME/hyperframes/.claude-plugin/marketplace.json" ]; then ok "HyperFrames 미리 받기 완료"; else bad "HyperFrames 미리 받기 안 됨 — 01-prereq 를 다시 실행"; fi
if [ -f "$KALS_HOME/gptaku_plugins/plugins/insane-design/.claude-plugin/plugin.json" ]; then ok "insane-design 미리 받기 완료"; else bad "insane-design 미리 받기 안 됨 — 01-prereq 를 다시 실행"; fi

section "4. Claude Code (수업 중 설치)"
claude_bin="$(find_claude)"
if [ -n "$claude_bin" ]; then ok "$("$claude_bin" --version 2>/dev/null | head -1)"; else info "아직 없음 — 02-install-claude 에서 설치"; fi
case ":$PATH:" in *":$HOME/.local/bin:"*) ok "PATH에 ~/.local/bin 있음" ;; *) info "PATH에 ~/.local/bin 없음 — 새 터미널을 열거나 02 실행" ;; esac
plugins_json="$HOME/.claude/plugins/installed_plugins.json"
for plugin in "insane-design@gptaku-plugins" "hyperframes@hyperframes"; do
  if [ -f "$plugins_json" ] && grep -q "\"$plugin\"" "$plugins_json"; then ok "플러그인 $plugin"; else info "플러그인 $plugin 아직 없음 — 03-skills"; fi
done
if [ -f "$HOME/.claude.json" ] && grep -q '"rea"' "$HOME/.claude.json"; then ok "REA MCP 연결됨"; else info "REA 아직 없음 — 03-skills"; fi

section "5. 잘못된 연결 설정 검사"
if [ -f "$HOME/.claude/settings.json" ] && grep -qE '"ANTHROPIC_(BASE_URL|AUTH_TOKEN|API_KEY)"' "$HOME/.claude/settings.json"; then
  bad "$HOME/.claude/settings.json 에 연결 주소나 키가 박혀 있습니다 (setup-claude 를 눌렀을 가능성) — 99-restore 실행"
else ok "전역 설정 깨끗함"; fi
if [ -n "${ANTHROPIC_BASE_URL:-}${ANTHROPIC_AUTH_TOKEN:-}${ANTHROPIC_API_KEY:-}" ]; then warn "이 터미널에 ANTHROPIC_ 변수가 들어 있습니다 — 새 터미널을 여세요"; else ok "터미널 환경변수 깨끗함"; fi

printf '\n결과: 실패 %d개, 주의 %d개\n' "$FAILS" "$WARNS"
[ "$FAILS" -eq 0 ] && printf '수업 준비 완료입니다.\n' || printf '[XX] 항목을 고친 뒤 다시 실행해 주세요. 모르겠으면 이 화면을 캡처해 강사에게 보내 주세요.\n'
