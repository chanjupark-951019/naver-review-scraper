# naver-review-scraper

네이버 브랜드스토어/스마트스토어 상품 리뷰를 **backend API로 전량 수집**하는 Claude Code 스킬.
무한스크롤 DOM 긁기 대비 **10배 이상 빠르고 안정적**.

- ✅ URL 1줄만 주면 끝 (예: `https://brand.naver.com/<채널>/products/<번호>`)
- ✅ 페이지 1회 방문으로 `originProductNo`·`checkoutMerchantNo` 자동 추출
- ✅ 페이지네이션 호출 + 429 자동 백오프 + graceful 종료
- ✅ 14컬럼 표준 xlsx 자동 생성
- ✅ brand.naver.com / smartstore.naver.com 둘 다 지원

## 설치 — Claude Code에 그대로 붙여넣기

> ※ 사전에 **Node.js**, **Python 3.x**, **git** 설치 필요 (자세한 건 아래 "필요 환경")

아래 프롬프트를 Claude Code 채팅창에 그대로 붙여넣으면 Claude가 알아서 설치합니다:

```
1. npm install -g agent-browser 로 agent-browser CLI를 글로벌 설치하고 agent-browser install 도 실행해줘.
2. https://github.com/chanjupark-951019/naver-review-scraper 이 레포를 클론해서 skills/ 폴더 안의 naver-review-scraper 스킬을 ~/.claude/skills/에 직접 복사해. /plugin 사용 금지. 다른 에이전트 설정은 무시해.
3. pip install openpyxl 도 실행해줘.
```

설치 후 Claude Code를 재시작하면 자동으로 트리거됩니다.

### (대안) 스크립트로 한 줄 설치

Claude 안 거치고 직접 실행하고 싶다면:

```bash
# Mac / Linux / Windows Git Bash
curl -fsSL https://raw.githubusercontent.com/chanjupark-951019/naver-review-scraper/main/install.sh | bash
```

```powershell
# Windows PowerShell
iwr -useb https://raw.githubusercontent.com/chanjupark-951019/naver-review-scraper/main/install.ps1 | iex
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

### 사전 요건 (없다면 먼저 설치)

- **Node.js (LTS)** — https://nodejs.org (npm이 같이 깔립니다)
- **Python 3.x** — https://python.org
- **git** — https://git-scm.com (Windows는 Git for Windows 추천 — Git Bash 포함)

### 자동 설치되는 것 (위 "설치" 프롬프트가 처리)

- Claude Code (CLI / Desktop / VSCode 확장 모두 지원)
- agent-browser CLI: `npm i -g agent-browser && agent-browser install`
- Python 패키지: `pip install openpyxl`

## 무엇이 들어있나

```
.claude-plugin/plugin.json           # 플러그인 메타 (CLI plugin 시스템 호환)
install.sh / install.ps1             # 한 줄 설치 스크립트 (대안)
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
A. `/plugin`은 Claude Code CLI 전용입니다. VSCode/Desktop 환경에서는 위 "설치" 프롬프트 또는 install 스크립트를 쓰세요.

**Q. 캡차가 뜨면?**
A. agent-browser 헤드 모드로 창을 띄우고 사용자가 직접 해결합니다. 일반 공개 상품은 보통 캡차 없이 통과.

**Q. 로그인이 필요한 상품?**
A. 같은 방식으로 사용자 본인이 한 번 로그인하면 같은 세션에서 이어서 진행.

**Q. 한 번에 몇 건까지?**
A. 1,500~2,000건 안정적으로 검증. 700ms 지연으로 약 1분/1,000건.

**Q. 업데이트는 어떻게?**
A. 같은 설치 프롬프트(또는 스크립트)를 다시 실행하면 최신 버전으로 덮어씁니다.

**Q. 제거는?**
A. Claude한테 "~/.claude/skills/naver-review-scraper 폴더 삭제해줘" 라고 부탁하거나, 직접 `rm -rf ~/.claude/skills/naver-review-scraper`.

## 라이선스
MIT
