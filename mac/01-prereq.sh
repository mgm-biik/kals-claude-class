#!/usr/bin/env bash
# KALS class, run at HOME before class (macOS).
# Installs Node.js, FFmpeg and Python with Homebrew, then pre-downloads the HyperFrames and
# insane-design plugin sources so the class Wi-Fi never has to carry hundreds of MB per student.
# Usage: curl -fsSL <raw url>/mac/01-prereq.sh | bash
set -euo pipefail

# Replaced with the published raw GitHub base URL when the repository is released.
readonly KALS_RAW_BASE="https://raw.githubusercontent.com/mgm-biik/kals-claude-class/main"
readonly KALS_HOME="$HOME/.kals"
readonly HYPERFRAMES_REPO="https://github.com/heygen-com/hyperframes"
readonly HYPERFRAMES_DIR="$KALS_HOME/hyperframes"
# Only the skills and the plugin manifest are needed; the full working tree is about 338 MB.
readonly HYPERFRAMES_SPARSE_PATHS="skills .claude-plugin"
readonly GPTAKU_REPO="https://github.com/fivetaku/gptaku_plugins"
readonly GPTAKU_DIR="$KALS_HOME/gptaku_plugins"
# Each gptaku plugin is a git submodule except gptaku-core, a plain folder that comes with the clone.
readonly GPTAKU_SUBMODULES="plugins/insane-design"
readonly HOMEBREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
readonly MIN_MACOS_MAJOR=13
readonly MIN_FREE_GB=3
readonly MIN_NODE="22.0.0"
readonly MIN_PYTHON="3.11.0"

say() { printf '\n==> %s\n' "$*"; }
ok() { printf '  [OK] %s\n' "$*"; }
warn() { printf '  [!!] %s\n' "$*"; }
die() { printf '  [XX] %s\n' "$*"; exit 1; }

version_ge() {
  awk -v a="$1" -v b="$2" 'BEGIN { split(a, x, "."); split(b, y, ".");
    for (i = 1; i <= 3; i++) { if (x[i] + 0 > y[i] + 0) exit 0; if (x[i] + 0 < y[i] + 0) exit 1 } exit 0 }'
}

# REA accepts Node 22.19+, 24.11+ or 26+; odd majors 23 and 25 are rejected.
node_ok() {
  command -v node >/dev/null 2>&1 || return 1
  local v major
  v="$(node --version | tr -d v)"
  major="${v%%.*}"
  case "$major" in
    22) version_ge "$v" "22.19.0" ;;
    24) version_ge "$v" "24.11.0" ;;
    23 | 25) return 1 ;;
    *) version_ge "$v" "$MIN_NODE" ;;
  esac
}

python_ok() {
  command -v python3 >/dev/null 2>&1 || return 1
  version_ge "$(python3 -c 'import sys; print("%d.%d.%d" % sys.version_info[:3])')" "$MIN_PYTHON"
}

load_brew() {
  local candidate
  for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [ -x "$candidate" ]; then eval "$("$candidate" shellenv)"; return 0; fi
  done
  command -v brew >/dev/null 2>&1
}

say "1/5 컴퓨터 확인"
mac_version="$(sw_vers -productVersion)"
[ "${mac_version%%.*}" -ge "$MIN_MACOS_MAJOR" ] || die "macOS $mac_version 입니다. 13 이상에서만 수업 도구가 돌아갑니다."
ok "macOS $mac_version"
free_gb="$(df -g "$HOME" | awk 'NR == 2 { print $4 }')"
[ "${free_gb:-0}" -ge "$MIN_FREE_GB" ] || die "남은 디스크가 ${free_gb}GB 입니다. ${MIN_FREE_GB}GB 이상 비운 뒤 다시 실행해 주세요."
ok "남은 디스크 ${free_gb}GB"

say "2/5 Homebrew (맥용 프로그램 설치 도구)"
if load_brew; then
  ok "이미 있음"
else
  warn "Homebrew를 설치합니다. 맥 로그인 비밀번호를 물어보면 입력하세요(입력해도 화면에 안 보입니다)."
  /bin/bash -c "$(curl -fsSL "$HOMEBREW_INSTALL_URL")" </dev/tty
  load_brew || die "Homebrew 설치를 확인하지 못했습니다. 터미널을 새로 열고 다시 실행해 주세요."
  # Make brew available in every new zsh, which is what Orca opens on macOS.
  brew_bin="$(command -v brew)"
  if ! grep -qs 'brew shellenv' "$HOME/.zprofile"; then
    printf '\neval "$(%s shellenv)"\n' "$brew_bin" >>"$HOME/.zprofile"
  fi
  ok "설치 완료"
fi

say "3/5 Node.js, FFmpeg, Python"
if node_ok; then ok "Node.js $(node --version)"; else brew install node; node_ok || die "Node.js 버전을 맞추지 못했습니다."; ok "Node.js $(node --version)"; fi
if command -v ffmpeg >/dev/null 2>&1; then ok "FFmpeg 있음"; else brew install ffmpeg; ok "FFmpeg 설치"; fi
if python_ok; then ok "Python $(python3 --version)"; else brew install python; hash -r; python_ok || die "Python 3.11 이상을 찾지 못했습니다."; ok "Python $(python3 --version)"; fi
git --version >/dev/null 2>&1 || die "Git이 없습니다. 'xcode-select --install' 을 실행한 뒤 다시 실행해 주세요."
ok "$(git --version)"

say "4/5 수업용 플러그인 미리 받기 (HyperFrames, insane-design)"
mkdir -p "$KALS_HOME"
if [ -f "$HYPERFRAMES_DIR/.claude-plugin/marketplace.json" ]; then
  ok "HyperFrames 이미 받음"
else
  rm -rf "$HYPERFRAMES_DIR"
  git clone -q --depth 1 --filter=blob:none --sparse "$HYPERFRAMES_REPO" "$HYPERFRAMES_DIR"
  # shellcheck disable=SC2086 # the path list is meant to split into arguments
  git -C "$HYPERFRAMES_DIR" sparse-checkout set $HYPERFRAMES_SPARSE_PATHS
  ok "HyperFrames 받음 ($(du -sh "$HYPERFRAMES_DIR" | cut -f1))"
fi
if [ -f "$GPTAKU_DIR/plugins/insane-design/.claude-plugin/plugin.json" ]; then
  ok "insane-design 이미 받음"
else
  rm -rf "$GPTAKU_DIR"
  git clone -q --depth 1 "$GPTAKU_REPO" "$GPTAKU_DIR"
  # shellcheck disable=SC2086
  git -C "$GPTAKU_DIR" submodule update -q --init --depth 1 $GPTAKU_SUBMODULES
  ok "insane-design 받음 ($(du -sh "$GPTAKU_DIR" | cut -f1))"
fi

say "5/5 영상 렌더용 브라우저와 REA 미리 받기"
npx --yes hyperframes@latest browser ensure >/dev/null && ok "HyperFrames 렌더 브라우저 준비" || warn "렌더 브라우저 준비 실패 — 수업에서 다시 시도합니다"
npm cache add rea-agents@latest >/dev/null 2>&1 && ok "REA 패키지 미리 받음" || warn "REA 미리 받기 실패 — 수업에서 받습니다"

printf '\n사전 준비가 끝났습니다. Orca와 freellmapi도 설치했는지 아래로 확인해 보세요.\n'
printf '  curl -fsSL %s/mac/00-doctor.sh | bash\n' "$KALS_RAW_BASE"
