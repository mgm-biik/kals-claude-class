#!/usr/bin/env bash
# KALS class, step 4 (macOS): install insane-design and HyperFrames from the copies 01-prereq
# downloaded at home, then connect REA as an MCP server. Run after logging in to Claude Code.
# Usage: curl -fsSL <raw url>/mac/03-skills.sh | bash      (KALS_SKIP_REA=1 skips REA)
set -euo pipefail

readonly KALS_HOME="$HOME/.kals"
readonly GPTAKU_DIR="$KALS_HOME/gptaku_plugins"
readonly HYPERFRAMES_DIR="$KALS_HOME/hyperframes"
readonly GPTAKU_REMOTE="fivetaku/gptaku_plugins"
readonly HYPERFRAMES_REMOTE="heygen-com/hyperframes"
# Remote fallback clones are large; give git more than the default 120 s.
export CLAUDE_CODE_PLUGIN_GIT_TIMEOUT_MS=300000

say() { printf '\n==> %s\n' "$*"; }
ok() { printf '  [OK] %s\n' "$*"; }
warn() { printf '  [!!] %s\n' "$*"; }
die() { printf '  [XX] %s\n' "$*"; exit 1; }

if [ -x "$HOME/.local/bin/claude" ]; then CLAUDE="$HOME/.local/bin/claude"
elif command -v claude >/dev/null 2>&1; then CLAUDE="$(command -v claude)"
else die "claude 를 찾지 못했습니다. 02-install-claude 를 먼저 실행하세요."; fi

# Add a marketplace unless one with the same name is already registered.
add_marketplace() {
  local name="$1" local_dir="$2" remote="$3" source
  if "$CLAUDE" plugin marketplace list 2>/dev/null | grep -q "$name"; then
    ok "마켓플레이스 $name 이미 등록됨"
    return
  fi
  if [ -d "$local_dir/.claude-plugin" ]; then
    source="$local_dir"
  else
    warn "미리 받은 $name 이 없어 인터넷에서 받습니다. 수백 MB라 오래 걸릴 수 있습니다."
    source="$remote"
  fi
  "$CLAUDE" plugin marketplace add "$source"
  ok "마켓플레이스 $name 등록"
}

install_plugin() {
  local id="$1"
  if "$CLAUDE" plugin list 2>/dev/null | grep -q "$id"; then ok "$id 이미 설치됨"; return; fi
  "$CLAUDE" plugin install "$id"
  ok "$id 설치"
}

say "1/3 insane-design (웹사이트 디자인을 분석하고 그 스타일로 만들어 주는 스킬)"
add_marketplace "gptaku-plugins" "$GPTAKU_DIR" "$GPTAKU_REMOTE"
install_plugin "insane-design@gptaku-plugins"

say "2/3 HyperFrames (HTML로 영상을 만드는 스킬)"
add_marketplace "hyperframes" "$HYPERFRAMES_DIR" "$HYPERFRAMES_REMOTE"
install_plugin "hyperframes@hyperframes"

say "3/3 REA (역분석 도구, MCP 서버로 연결)"
if [ "${KALS_SKIP_REA:-0}" = "1" ]; then
  warn "KALS_SKIP_REA=1 이라 건너뜁니다"
elif grep -qs '"rea"' "$HOME/.claude.json"; then
  ok "REA 이미 연결됨"
else
  mkdir -p "$KALS_HOME"
  # REA prints its whole plan for every supported client; keep it in a log and report the outcome.
  npx --yes rea-agents@latest setup --client claude_code --yes </dev/null >"$KALS_HOME/rea-setup.log" 2>&1 || true
  if grep -qs '"rea"' "$HOME/.claude.json"; then
    ok "REA 연결 (되돌리려면 npx rea-agents uninstall)"
  else
    warn "REA 연결 실패 — 기록: $KALS_HOME/rea-setup.log (수업 뒤에 다시 시도해도 됩니다)"
  fi
fi

printf '\n설치가 끝났습니다. 열려 있는 Claude Code가 있으면 /exit 로 닫고 claude 로 다시 여세요.\n'
printf '다시 연 뒤 /plugin 과 /mcp 로 설치된 것을 확인합니다.\n'
