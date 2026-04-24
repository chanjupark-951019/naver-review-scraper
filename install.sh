#!/usr/bin/env bash
# naver-review-scraper 설치 스크립트
# 사용:
#   curl -fsSL https://raw.githubusercontent.com/chanjupark-951019/naver-review-scraper/main/install.sh | bash

set -e

SKILL_NAME="naver-review-scraper"
REPO="https://github.com/chanjupark-951019/naver-review-scraper.git"
TARGET="${1:-$HOME/.claude/skills}"

echo "═══════════════════════════════════════════════════════"
echo "  naver-review-scraper 설치"
echo "═══════════════════════════════════════════════════════"

# 사전 환경 점검
echo ""
echo "[1/5] 환경 점검..."
MISSING=()
command -v node >/dev/null 2>&1 || MISSING+=("Node.js (https://nodejs.org)")
command -v npm  >/dev/null 2>&1 || MISSING+=("npm (Node.js와 함께 설치됨)")
command -v git  >/dev/null 2>&1 || MISSING+=("git (https://git-scm.com)")
if ! (command -v python3 >/dev/null 2>&1 || command -v python >/dev/null 2>&1); then
  MISSING+=("Python 3.x (https://python.org)")
fi
if [ ${#MISSING[@]} -ne 0 ]; then
  echo "  ✗ 다음이 먼저 설치되어야 합니다:"
  printf '    - %s\n' "${MISSING[@]}"
  echo "  설치 후 이 스크립트를 다시 실행해주세요."
  exit 1
fi
echo "  ✓ node $(node --version), npm $(npm --version), git, python OK"

# 시스템 Chrome 자동 감지
echo ""
echo "[2/5] 시스템 Chrome 감지..."
CHROME_PATH=""
for p in \
  "/c/Program Files/Google/Chrome/Application/chrome.exe" \
  "/c/Program Files (x86)/Google/Chrome/Application/chrome.exe" \
  "$LOCALAPPDATA/Google/Chrome/Application/chrome.exe" \
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  "/usr/bin/google-chrome" \
  "/usr/bin/chromium" \
  "/usr/bin/chromium-browser"; do
  if [ -f "$p" ]; then CHROME_PATH="$p"; break; fi
done

if [ -n "$CHROME_PATH" ]; then
  echo "  ✓ 시스템 Chrome 발견: $CHROME_PATH"
  echo "  → agent-browser install (Chromium 200MB 다운로드)을 건너뜁니다."
else
  echo "  ✗ 시스템 Chrome을 찾지 못했습니다."
  echo "  → agent-browser install을 실행합니다 (약 5~15분 소요, ~200MB 다운로드)"
fi

# agent-browser 설치
echo ""
echo "[3/5] agent-browser CLI 글로벌 설치..."
npm install -g agent-browser
echo "  ✓ agent-browser $(agent-browser --version 2>/dev/null || echo 'installed')"

if [ -z "$CHROME_PATH" ]; then
  echo ""
  echo "[3.5/5] Chromium 다운로드 (시간이 걸립니다, 진행 중...)"
  agent-browser install
fi

# Python 패키지
echo ""
echo "[4/5] Python 패키지 설치..."
if command -v pip3 >/dev/null 2>&1; then PIP=pip3; else PIP=pip; fi
$PIP install --quiet openpyxl
echo "  ✓ openpyxl"

# 스킬 클론·복사
echo ""
echo "[5/5] 스킬 설치..."
mkdir -p "$TARGET"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
git clone --depth 1 --quiet "$REPO" "$TMP/repo"
DEST="$TARGET/$SKILL_NAME"
[ -d "$DEST" ] && rm -rf "$DEST"
cp -r "$TMP/repo/skills/$SKILL_NAME" "$TARGET/"
echo "  ✓ $DEST"

# 시스템 Chrome 사용 안내
echo ""
echo "═══════════════════════════════════════════════════════"
echo "  설치 완료"
echo "═══════════════════════════════════════════════════════"
if [ -n "$CHROME_PATH" ]; then
  echo ""
  echo "▸ 시스템 Chrome을 쓰려면 환경변수를 영구 설정하세요:"
  case "$(uname -s)" in
    Darwin*|Linux*)
      echo "    echo 'export AGENT_BROWSER_EXECUTABLE_PATH=\"$CHROME_PATH\"' >> ~/.bashrc"
      echo "    source ~/.bashrc";;
    *)
      echo "    setx AGENT_BROWSER_EXECUTABLE_PATH \"$CHROME_PATH\""
      echo "    (PowerShell/cmd 새 창부터 적용)";;
  esac
fi
echo ""
echo "▸ Claude Code를 재시작하면 자동으로 트리거됩니다."
echo "▸ 사용: 채팅창에 'https://brand.naver.com/<채널>/products/<번호> 리뷰 수집해줘'"
