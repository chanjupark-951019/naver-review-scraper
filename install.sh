#!/usr/bin/env bash
# naver-review-scraper 설치 스크립트
# 사용:
#   curl -fsSL https://raw.githubusercontent.com/chanjupark-951019/naver-review-scraper/main/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/chanjupark-951019/naver-review-scraper/main/install.sh | bash -s -- ./project-skills
#
# 첫 인자로 설치 경로를 줄 수 있음. 없으면 ~/.claude/skills (글로벌)에 설치.

set -e

SKILL_NAME="naver-review-scraper"
REPO="https://github.com/chanjupark-951019/naver-review-scraper.git"
TARGET="${1:-$HOME/.claude/skills}"

# Windows MSYS path normalization
case "$TARGET" in
  /c/*) TARGET="C:${TARGET#/c}" ;;
esac

echo "Target: $TARGET"
mkdir -p "$TARGET"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Cloning..."
git clone --depth 1 --quiet "$REPO" "$TMP/repo"

DEST="$TARGET/$SKILL_NAME"
if [ -d "$DEST" ]; then
  echo "Removing existing $DEST"
  rm -rf "$DEST"
fi

cp -r "$TMP/repo/skills/$SKILL_NAME" "$TARGET/"

echo ""
echo "Installed: $DEST"
echo ""
echo "Next steps:"
echo "  1. Restart Claude Code (필요한 경우)."
echo "  2. 채팅창에 네이버 상품 URL을 그대로 던지면 자동 트리거됩니다:"
echo "     예) https://brand.naver.com/<채널>/products/<번호> 리뷰 수집해줘"
echo ""
echo "필요 환경:"
echo "  - agent-browser CLI: npm i -g agent-browser && agent-browser install"
echo "  - Python 3.x + openpyxl: pip install openpyxl"
