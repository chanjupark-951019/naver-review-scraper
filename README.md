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

## 설치

### 사전 요건 (한 번만)

| 도구 | 다운로드 | 설치 시 주의 |
|------|----------|--------------|
| **Node.js (LTS)** | https://nodejs.org | 기본 옵션으로 설치 |
| **Python 3.x** | https://python.org/downloads/ | ⚠ 설치 첫 화면 **"Add python.exe to PATH" 반드시 체크**. Microsoft Store의 Python은 사용 금지 (가짜 alias 문제) |
| **git** | https://git-scm.com | Windows는 Git for Windows |
| **Google Chrome** | https://www.google.com/chrome | 대부분 이미 있음 |

위 4개 중 없는 것만 먼저 설치하고, **PC를 한 번 재시작**해주세요. (PATH 환경변수 갱신을 위해)

#### Windows 사용자 추가 사전 작업 (PowerShell)

PowerShell을 **관리자 권한**으로 한 번만 열어 다음을 실행해주세요. (Claude가 환경변수를 설정할 때 막히지 않도록)

```
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

`Y` 입력 후 Enter. 한 번 해두면 영구 적용됩니다.

---

### 설치 — Claude Code 채팅창에 그대로 붙여넣기

**터미널 명령어 직접 치지 마세요.** 아래 프롬프트를 **Claude Code 채팅창에 그대로 붙여넣으면** Claude가 알아서 다 처리합니다.

```
이 GitHub 스킬을 ~/.claude/skills/ 에 설치해줘:
https://github.com/chanjupark-951019/naver-review-scraper

다음 순서로 진행해줘. 각 단계가 끝날 때마다 어느 단계까지 끝났는지 한 줄로 보고만 하고, 코드 분석이나 테스트, 검증 같은 부가 작업은 일절 하지 마.

1. 사전 점검: node --version, npm --version, git --version 출력. python은 `python --version` 시도 후, 응답이 없거나 Windows Store가 열리는 alias이면(빈 출력이거나 'was not found' 메시지) 실패로 간주하고 `python3 --version`도 시도. 둘 다 실패하면 사용자에게 "python.org에서 Python 3.x 받고 'Add to PATH' 체크 후 PC 재시작" 안내 후 즉시 중단. node/npm/git 중 없는 것도 같은 방식으로 중단 안내.

2. 시스템 Chrome 자동 감지. 다음 경로 중 존재하는 첫 번째 파일을 사용:
   - Windows: C:\Program Files\Google\Chrome\Application\chrome.exe
   - Windows: C:\Program Files (x86)\Google\Chrome\Application\chrome.exe
   - Windows: $LOCALAPPDATA\Google\Chrome\Application\chrome.exe
   - Mac: /Applications/Google Chrome.app/Contents/MacOS/Google Chrome
   - Linux: /usr/bin/google-chrome 또는 /usr/bin/chromium
   발견하면 그 경로를 변수에 저장. 못 찾으면 변수는 빈 값.

3. npm install -g agent-browser 실행. (Chromium 다운로드 X — 다음 단계에서 결정)

4. 2단계에서 Chrome을 찾았으면:
   - 환경변수 AGENT_BROWSER_EXECUTABLE_PATH를 그 경로로 영구 설정 (Windows: setx 명령 또는 [Environment]::SetEnvironmentVariable(..., 'User'). Mac/Linux: ~/.bashrc 또는 ~/.zshrc에 export 추가).
   - "agent-browser install" 절대 실행 금지. (Chromium 200MB 다운로드는 회사 네트워크에서 10분 이상 걸려서 건너뜀.)
   못 찾았으면 그제서야 "agent-browser install" 실행. 시간이 5~15분 걸린다고 사용자에게 미리 알려.

5. git clone https://github.com/chanjupark-951019/naver-review-scraper 임시 폴더에 받은 뒤, skills/naver-review-scraper 폴더만 ~/.claude/skills/ 안으로 복사. 기존에 같은 이름 폴더 있으면 먼저 삭제. 임시 폴더는 정리.

6. python -m pip install openpyxl 실행 (`pip` 직접 호출보다 항상 안전).

7. 완료. 사용자에게 정확히 다음 두 줄을 안내:
   - "Claude Code를 한 번 종료했다가 다시 열어주세요. (Desktop 앱은 시스템 트레이에서 우클릭 → Quit 후 재실행 / VSCode 확장은 Ctrl+Shift+P → 'Developer: Reload Window' / CLI는 새 터미널 세션)"
   - "재시작 후 채팅창에 '네이버 상품 URL 리뷰 수집해줘' 형태로 입력하시면 됩니다."

주의 (반드시 지킬 것):
- /plugin 명령은 이 환경에서 안 됨. 사용 금지.
- 다른 에이전트 설정·MCP·hooks는 전혀 건드리지 마.
- 단계별 결과만 짧게 한 줄 보고. 코드 인스펙션·테스트 실행·dry-run 금지.
- bash/powershell 명령 실행 시 사용자 승인이 필요하면 그냥 진행하고, 거부되면 다음 단계로 넘기지 말고 사용자에게 "허용 클릭이 필요합니다"만 한 줄 안내.
- 임시 폴더는 OS 표준 temp 위치 사용 (Windows: $env:TEMP, Mac/Linux: /tmp 또는 mktemp).
- 사용자명/경로에 한글이나 공백이 있어도 따옴표로 감싸서 처리.
```

설치 완료 후 **Claude Code를 한 번 종료했다가 다시 열어주세요**. 그러면 스킬이 자동 로드됩니다.

> 💡 **설치 도중 "이 명령을 실행해도 되나요?" 같은 승인 팝업이 7~10번 뜹니다** (npm install, git clone, setx, pip 등). 모두 **허용**을 누르세요. 한 번이라도 거부하면 그 단계에서 멈추니 주의.

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

### "node/npm/git/python을 찾을 수 없습니다" (1단계 실패)
사전 요건이 설치 안 됐거나, 설치했지만 PATH 갱신이 안 된 상태입니다. 위 사전 요건 표에서 빠진 도구 설치 후 **PC 재시작**.

### "agent-browser install 중 멈춘 것 같음"
설치 프롬프트의 **2단계가 작동했다면 발생하지 않을 일입니다**. 만약 시스템 Chrome을 못 찾았다면 5~15분 정도 기다려주세요 (200MB 다운로드 중). 더 오래 걸리면 Chrome을 새로 설치하고 (https://www.google.com/chrome) 위 설치 프롬프트를 다시 한 번 실행하세요 — 두 번째 실행은 Chrome을 감지해 다운로드를 건너뜁니다.

### Windows PowerShell — "이 시스템에서 스크립트를 실행할 수 없으므로..."
Claude가 PowerShell 명령을 실행할 때 막힐 수 있습니다. 한 번만 다음을 사용자가 직접 PowerShell(관리자 권한)에서 실행:
```
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

### npm 글로벌 설치가 EACCES / EPERM
Windows는 PowerShell을 **관리자 권한**으로 다시 열고, 설치 프롬프트를 Claude에게 다시 입력해주세요.

### 캡차가 떠요
크롤링 시 agent-browser 헤드 모드로 창이 뜹니다. 직접 풀어주시면 같은 세션에서 이어서 진행. 일반 공개 상품은 보통 캡차 없이 통과.

### 로그인이 필요한 상품
같은 방식으로 사용자 본인이 한 번 로그인하면 같은 세션에서 진행.

---

## 무엇이 들어있나

```
.claude-plugin/plugin.json           # 플러그인 메타 (CLI plugin 시스템 호환)
install.sh / install.ps1             # (참고용) 같은 동작을 셸 스크립트로 구현한 버전
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

- **업데이트**: 위 설치 프롬프트를 다시 채팅창에 붙여넣으면 최신 버전으로 덮어씁니다.
- **제거**: Claude한테 "`~/.claude/skills/naver-review-scraper` 폴더 삭제해줘" 요청.

## 라이선스
MIT
