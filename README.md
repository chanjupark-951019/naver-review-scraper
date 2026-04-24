# naver-review-scraper

네이버 브랜드스토어/스마트스토어 상품 리뷰를 **backend API로 전량 수집**하는 Claude Code 스킬.
무한스크롤 DOM 긁기 대비 **10배 이상 빠르고 안정적**.

- ✅ URL 1줄만 주면 끝 (예: `https://brand.naver.com/<채널>/products/<번호>`)
- ✅ 페이지 1회 방문으로 `originProductNo`·`checkoutMerchantNo` 자동 추출
- ✅ 페이지네이션 호출 + 429 자동 백오프 + graceful 종료
- ✅ 14컬럼 표준 xlsx 자동 생성
- ✅ brand.naver.com / smartstore.naver.com 둘 다 지원
- ✅ **시스템 Chrome 자동 사용** — Chromium 200MB 재다운로드 안 함

---

## 설치 — 한 줄 (권장)

설치 스크립트가 사전 환경 점검 → **시스템 Chrome 자동 감지** → 스킬 복사 → 환경변수 설정까지 한 번에 처리합니다. 시스템 Chrome이 있으면 `agent-browser install`(약 200MB / 5~15분)을 자동 건너뜁니다.

### Windows PowerShell

```powershell
iwr -useb https://raw.githubusercontent.com/chanjupark-951019/naver-review-scraper/main/install.ps1 | iex
```

### Mac / Linux / Git Bash

```bash
curl -fsSL https://raw.githubusercontent.com/chanjupark-951019/naver-review-scraper/main/install.sh | bash
```

설치 완료 후 **Claude Code를 재시작**하면 끝.

---

## 사전 요건

설치 스크립트가 시작 시 자동으로 점검합니다. 없으면 설치 링크를 안내하고 종료합니다.

| 도구 | 다운로드 |
|------|----------|
| Node.js (LTS) | https://nodejs.org |
| Python 3.x | https://python.org |
| git | https://git-scm.com |
| Google Chrome | https://www.google.com/chrome (대부분 PC에 이미 있음) |

> Chrome이 없으면 자동으로 Chromium(200MB)을 다운로드합니다 (5~15분). 회사 네트워크가 느리면 시간이 더 걸릴 수 있으니 다른 작업하면서 대기하세요.

---

## 사용법

설치 후 Claude Code 채팅창에 자연어로 호출:

```
https://brand.naver.com/edgewall/products/11071342257 이거 리뷰 수집해줘
```

또는

```
이 스마트스토어 상품 리뷰 뽑아줘 — https://smartstore.naver.com/alab-st/products/11927271430
```

자동으로 ① 페이지 방문 → ② ID 추출 → ③ API 호출(429 자동 백오프 포함) → ④ 샘플·null 비율 보고 → ⑤ `output/naver.com/<채널>_<상품번호>/<채널>_<모델>_reviews_<타임스탬프>.xlsx` 저장.

---

## 트러블슈팅

### Windows PowerShell — "이 시스템에서 스크립트를 실행할 수 없으므로..."
실행 정책 변경:
```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

### npm 글로벌 설치가 EACCES / EPERM으로 실패
- Windows: PowerShell을 **관리자 권한**으로 다시 열고 실행
- Mac/Linux: `sudo npm install -g agent-browser` 또는 `npm config get prefix`로 권한 가능 위치 확인

### `agent-browser` 명령이 안 잡힘 (`command not found`)
설치 직후 같은 셸에선 PATH 갱신이 안 될 수 있습니다 — **터미널을 새 창으로 열고** 다시 시도.

### `agent-browser install`이 너무 오래 걸림 (10분 초과)
회사 방화벽/프록시가 Chromium 다운로드 서버를 막고 있을 수 있습니다.
**해결 1**: 시스템에 Chrome을 설치한 뒤 (https://www.google.com/chrome) 위 install 스크립트를 다시 실행 — Chrome을 자동 감지해 다운로드를 건너뜁니다.
**해결 2**: 환경변수 직접 설정:
```powershell
# Windows (사용자 스코프, 영구)
[Environment]::SetEnvironmentVariable('AGENT_BROWSER_EXECUTABLE_PATH', 'C:\Program Files\Google\Chrome\Application\chrome.exe', 'User')
```
```bash
# Mac/Linux
echo 'export AGENT_BROWSER_EXECUTABLE_PATH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"' >> ~/.bashrc
source ~/.bashrc
```

### 캡차가 떠요
agent-browser 헤드 모드로 창이 뜹니다. 직접 풀어주시면 같은 세션에서 이어서 진행. 일반 공개 상품은 보통 캡차 없이 통과.

### 로그인이 필요한 상품
같은 방식으로 사용자 본인이 한 번 로그인하면 같은 세션에서 진행.

---

## (대안) Claude한테 부탁하기

스크립트 안 돌리고 Claude한테 직접:

```
이 GitHub repo를 ~/.claude/skills 에 설치해줘.
중요: 시스템에 이미 Chrome이 있으면 'agent-browser install'은 절대 실행하지 말고,
대신 환경변수 AGENT_BROWSER_EXECUTABLE_PATH를 Chrome 경로로 영구 설정해줘.
Chrome이 없을 때만 'agent-browser install'을 실행해.

repo: https://github.com/chanjupark-951019/naver-review-scraper
```

---

## 무엇이 들어있나

```
.claude-plugin/plugin.json           # 플러그인 메타 (CLI plugin 시스템 호환)
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

## 업데이트·제거

- **업데이트**: 같은 install 스크립트를 다시 실행하면 최신 버전으로 덮어씁니다.
- **제거**: `~/.claude/skills/naver-review-scraper` 폴더 삭제.

## 라이선스
MIT
