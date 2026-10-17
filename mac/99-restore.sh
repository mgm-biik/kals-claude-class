#!/usr/bin/env bash
# KALS class (macOS): undo gateway settings that can redirect every Claude Code session.
# - removes ANTHROPIC_* keys from ~/.claude/settings.json (left there by `npx freellmapi setup-claude`)
#   after saving a timestamped backup
# - reports shell startup files that export ANTHROPIC_* (it does not edit them)
# - optionally deletes the saved kals-free key
# Plugins stay installed. Usage: curl -fsSL <raw url>/mac/99-restore.sh | bash
set -euo pipefail

readonly SETTINGS="$HOME/.claude/settings.json"
readonly KEYCHAIN_SERVICE="kals-freellmapi"
readonly GATEWAY_KEYS="ANTHROPIC_BASE_URL ANTHROPIC_AUTH_TOKEN ANTHROPIC_API_KEY ANTHROPIC_MODEL ANTHROPIC_DEFAULT_OPUS_MODEL ANTHROPIC_DEFAULT_SONNET_MODEL ANTHROPIC_DEFAULT_HAIKU_MODEL CLAUDE_CODE_AUTO_COMPACT_WINDOW CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY"

say() { printf '\n==> %s\n' "$*"; }
ok() { printf '  [OK] %s\n' "$*"; }
warn() { printf '  [!!] %s\n' "$*"; }

say "1/3 전역 설정(~/.claude/settings.json)"
if [ -f "$SETTINGS" ] && grep -qE '"ANTHROPIC_(BASE_URL|AUTH_TOKEN|API_KEY)"' "$SETTINGS"; then
  backup="$SETTINGS.kals-backup-$(date +%Y%m%d-%H%M%S)"
  cp "$SETTINGS" "$backup"
  KEYS="$GATEWAY_KEYS" node -e '
    const fs = require("fs");
    const path = process.argv[1];
    const data = JSON.parse(fs.readFileSync(path, "utf8"));
    for (const k of process.env.KEYS.split(" ")) if (data.env) delete data.env[k];
    if (data.env && Object.keys(data.env).length === 0) delete data.env;
    fs.writeFileSync(path, JSON.stringify(data, null, 2) + "\n");
  ' "$SETTINGS"
  ok "연결 설정을 지웠습니다. 원본은 $backup 에 남겨 두었습니다."
else
  ok "깨끗합니다"
fi
ls "$SETTINGS".backup-* >/dev/null 2>&1 && warn "freellmapi 가 만든 백업이 있습니다: $(ls "$SETTINGS".backup-* | tr '\n' ' ')"

say "2/3 셸 시작 파일"
found=0
for f in "$HOME/.zshrc" "$HOME/.zprofile" "$HOME/.zshenv" "$HOME/.bash_profile" "$HOME/.bashrc"; do
  if grep -nqs 'ANTHROPIC_' "$f"; then warn "$f 에 ANTHROPIC_ 설정이 있습니다(자동으로 고치지 않음):"; grep -n 'ANTHROPIC_' "$f" | sed -E 's/(TOKEN|KEY)=.*/\1=<가림>/'; found=1; fi
done
[ "$found" -eq 0 ] && ok "깨끗합니다"

say "3/3 kals-free 에 저장한 키"
if security find-generic-password -s "$KEYCHAIN_SERVICE" -a "$USER" >/dev/null 2>&1; then
  printf '  저장된 freellmapi 키를 지울까요? [y/N] '
  read -r answer </dev/tty || answer=""
  if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
    security delete-generic-password -s "$KEYCHAIN_SERVICE" -a "$USER" >/dev/null
    ok "지웠습니다"
  else
    ok "그대로 둡니다"
  fi
else
  ok "저장된 키 없음"
fi

printf '\n끝났습니다. 새 터미널에서 claude 를 열고 /status 로 로그인 방식이 구독인지 확인하세요.\n'
