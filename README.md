# naver-review-scraper

네이버 브랜드스토어/스마트스토어 상품 리뷰를 **backend API로 전량 수집**하는 Claude Code 스킬.
무한스크롤 DOM 긁기 대비 **10배 이상 빠르고 안정적**.

- ✅ URL 1줄만 주면 끝 (예: `https://brand.naver.com/<채널>/products/<번호>`)
- ✅ 페이지 1회 방문으로 `originProductNo`·`checkoutMerchantNo` 자동 추출
- ✅ 페이지네이션 호출 + 429 자동 백오프 + graceful 종료
- ✅ 14컬럼 표준 xlsx 자동 생성
- ✅ brand.naver.com / smartstore.naver.com 둘 다 지원

## 설치 (한 줄 — 사용자 스코프 글로벌)

설치 위치: `~/.claude/skills/naver-review-scraper/` (모든 프로젝트에서 사용 가능)

### Mac / Linux / Windows Git Bash

```bash
curl -fsSL https://raw.githubusercontent.com/chanjupark-951019/naver-review-scraper/main/install.sh | bash
```

### Windows PowerShell

```powershell
iwr -useb https://raw.githubusercontent.com/chanjupark-951019/naver-review-scraper/main/install.ps1 | iex
```

### 또는 Claude한테 부탁하기

Claude Code 채팅창에 그냥:
```
이 GitHub repo를 ~/.claude/skills 에 설치해줘:
https://github.com/chanjupark-951019/naver-review-scraper
```

설치 후 Claude Code를 재시작하면 자동으로 트리거됩니다.

### (선택) 프로젝트 단위로만 설치하려면

특정 프로젝트에만 적용하고 싶다면 첫 인자로 경로 지정:

```bash
# Git Bash / Mac / Linux
curl -fsSL https://raw.githubusercontent.com/chanjupark-951019/naver-review-scraper/main/install.sh | bash -s -- ./.claude/skills

# PowerShell
$env:NRS_TARGET = ".\.claude\skills"; iwr -useb https://raw.githubusercontent.com/chanjupark-951019/naver-review-scraper/main/install.ps1 | iex
```

## 사용법

설치만 해두면 자연어로 호출 가능. Claude Code에 다음과 같이 입력:

```
https://brand.naver.com/edgewall/products/11071342257 이거 리뷰 수집해줘
```

또는

```
이 스마트스토어 상품 리뷰 뽑아줘 — https://smartstore.naver.com/alab-st/products/11927271430
```

자동으로:
1. 페이지 방문 → ID 추출
2. API 1샘플 검증
3. 전체 페이지 루프 수집 (지연 700ms, 429 자동 백오프)
4. 행 수·null 비율·샘플 5행으로 품질 확인
5. `output/naver.com/<채널>_<상품번호>/<채널>_<모델>_reviews_<타임스탬프>.xlsx` 저장

## 필요 환경

- Claude Code (CLI / Desktop / VSCode 확장 모두 지원)
- agent-browser CLI: `npm i -g agent-browser && agent-browser install`
- Python 3.x + openpyxl: `pip install openpyxl`
- git (설치 스크립트가 git clone 사용)

## 무엇이 들어있나

```
.claude-plugin/plugin.json           # 플러그인 메타 (Claude Code CLI plugin 시스템용)
install.sh / install.ps1             # 한 줄 설치 스크립트
skills/naver-review-scraper/
├── SKILL.md                         # 메인 스킬 정의 (Claude가 자동 로드)
├── references/
│   ├── api_endpoint.md              # query-pages API 스키마
│   └── batch_classify_workflow.md   # 수집 → claim 분류 → PDF 리포트 전 과정
└── scripts/
    ├── parse_url.py                 # URL 파서 (channel + productNo)
    ├── fetch_reviews.js             # in-page fetch 루프 템플릿
    └── merge_and_save.py            # 병합·중복제거·xlsx 생성
```

## 지원 도메인

- `brand.naver.com/<채널>/products/<번호>` (브랜드스토어)
- `smartstore.naver.com/<채널>/products/<번호>` (스마트스토어)
- `m.smartstore.naver.com/...` (모바일)

## 자주 묻는 것

**Q. `/plugin` 명령이 안 먹습니다.**
A. `/plugin`은 Claude Code CLI 전용입니다. VSCode/Desktop은 위의 `install.sh`/`install.ps1`로 설치하세요.

**Q. 캡차가 뜨면?**
A. agent-browser 헤드 모드로 창을 띄우고 사용자가 직접 해결합니다(스킬 내 HITL 워크플로우). 일반 공개 상품은 보통 캡차 없이 통과.

**Q. 로그인이 필요한 상품?**
A. 같은 방식으로 사용자 본인이 한 번 로그인하면 같은 세션에서 이어서 진행.

**Q. 한 번에 몇 건까지?**
A. 1,500~2,000건 안정적으로 검증. 700ms 지연으로 약 1분/1,000건.

**Q. 업데이트는 어떻게?**
A. 같은 install 명령을 다시 실행하면 최신 버전으로 덮어씁니다.

**Q. 제거는?**
A. `rm -rf ~/.claude/skills/naver-review-scraper` (PowerShell: `Remove-Item -Recurse -Force "$HOME\.claude\skills\naver-review-scraper"`)

## 라이선스
MIT
