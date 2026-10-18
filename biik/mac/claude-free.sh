#!/usr/bin/env bash
# Biik onboarding (macOS): install the `claude-free` command and open Claude Code through the
# local freellmapi gateway. The gateway settings live only in that one Claude Code process, so
# plain `claude` keeps using the paid plan. Same behaviour as mac/04-free.sh (`kals-free`); only
# the command name and the keychain item differ, so both commands can live side by side.
# Usage: curl -fsSL <raw url>/biik/mac/claude-free.sh | bash
set -euo pipefail

readonly LAUNCHER="$HOME/.local/bin/claude-free"

mkdir -p "$(dirname "$LAUNCHER")"
cat >"$LAUNCHER" <<'LAUNCHER_EOF'
#!/usr/bin/env bash
# claude-free: open Claude Code through the local freellmapi gateway, for this session only.
#   claude-free             start (asks for the freellmapi unified key the first time)
#   claude-free --reset-key forget the saved key and ask again
#   claude-free -p "hi"     any other arguments go to claude
set -euo pipefail

readonly KEYCHAIN_SERVICE="freellmapi-unified-key"
readonly DEFAULT_PORT=31415
readonly CONFIG="$HOME/Library/Application Support/FreeLLMAPI/config.json"
readonly KEY_PREFIX="freellmapi-"
# Groq rejects max_tokens above 16384 and Claude Code asks for more, so cap the output.
readonly MAX_OUTPUT_TOKENS=16000

port=""
[ -f "$CONFIG" ] && port="$(sed -nE 's/.*"port"[[:space:]]*:[[:space:]]*([0-9]+).*/\1/p' "$CONFIG" | head -1)"
base="http://127.0.0.1:${port:-$DEFAULT_PORT}"

if [ "${1:-}" = "--reset-key" ]; then
  security delete-generic-password -s "$KEYCHAIN_SERVICE" -a "$USER" >/dev/null 2>&1 || true
  shift
fi

if ! curl -fsS --max-time 3 "$base/health" >/dev/null 2>&1; then
  echo "[XX] freellmapi 가 꺼져 있습니다 ($base). FreeLLMAPI 앱을 켠 뒤 다시 실행하세요." >&2
  exit 1
fi

key="$(security find-generic-password -s "$KEYCHAIN_SERVICE" -a "$USER" -w 2>/dev/null || true)"
if [ -z "$key" ]; then
  echo "freellmapi 앱 → Claude Code 카드 → 수동 연결의 API_KEY(통합 키)를 복사해 오세요." >/dev/tty
  printf '통합 키를 붙여넣고 Enter (화면에 보이지 않습니다): ' >/dev/tty
  IFS= read -rs key </dev/tty
  echo >/dev/tty
  key="$(printf '%s' "$key" | tr -d '[:space:]')"
  case "$key" in
    "$KEY_PREFIX"*) ;;
    *) echo "[XX] $KEY_PREFIX 로 시작하는 키가 아닙니다. 다시 복사해 오세요." >&2; exit 1 ;;
  esac
  # Pass the header through stdin so the key never shows up in the process list.
  code="$(printf 'header = "Authorization: Bearer %s"\n' "$key" |
    curl -s -o /dev/null -w '%{http_code}' --max-time 5 -K - "$base/v1/models")"
  if [ "$code" != "200" ]; then
    echo "[XX] freellmapi 가 이 키를 받지 않았습니다 (응답 $code). 앱에서 키를 다시 복사하세요." >&2
    exit 1
  fi
  printf 'add-generic-password -U -s %s -a %s -w %s\n' "$KEYCHAIN_SERVICE" "$USER" "$key" | security -i >/dev/null
  echo "[OK] 키를 macOS 키체인에 저장했습니다." >/dev/tty
fi

if [ -x "$HOME/.local/bin/claude" ]; then claude_bin="$HOME/.local/bin/claude"; else claude_bin="claude"; fi
unset ANTHROPIC_API_KEY
export ANTHROPIC_BASE_URL="$base"
export ANTHROPIC_AUTH_TOKEN="$key"
export CLAUDE_CODE_MAX_OUTPUT_TOKENS="$MAX_OUTPUT_TOKENS"
# If the insane-design plugin is installed, its gptaku-core adds skill-routing rules to every prompt;
# small free models get confused by them.
export GPTAKU_ROUTER=off
if [ -t 0 ]; then exec "$claude_bin" "$@"; else exec "$claude_bin" "$@" </dev/tty; fi
LAUNCHER_EOF
chmod +x "$LAUNCHER"

echo "[OK] claude-free 명령을 설치했습니다: $LAUNCHER"
echo "     다음부터는 터미널에서 claude-free 만 치면 됩니다. 창을 닫으면 무료 연결도 함께 끝납니다."
# A shell alias with the same name wins over the installed command in interactive shells.
if grep -qE '^[[:space:]]*alias[[:space:]]+claude-free=' "$HOME/.zshrc" 2>/dev/null; then
  echo "[!!] ~/.zshrc 에 claude-free alias 가 있습니다. 터미널에서는 그 alias 가 이 명령보다 먼저 실행됩니다."
fi
echo
exec "$LAUNCHER"
