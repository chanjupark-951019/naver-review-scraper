---
name: naver-review-scraper
description: 네이버 브랜드스토어/스마트스토어 상품의 리뷰를 직접 백엔드 API 호출로 전량 수집해 엑셀로 저장한다. URL만 주면 페이지 1회 방문으로 originProductNo·checkoutMerchantNo를 추출한 뒤 query-pages API를 페이지네이션 호출. 무한스크롤 DOM 긁기 대비 10배 이상 빠르고 안정적. brand.naver.com / smartstore.naver.com / shopping.naver.com 도메인이 포함된 URL이면 트리거. "네이버 리뷰 수집", "스마트스토어 리뷰", "브랜드스토어 리뷰", "쇼핑 리뷰 크롤링" 같은 표현에도 반응. 후속 분석 파이프라인(claim 단위 분류·xlsx 생성·PDF 리포트)과 직접 연동된다.
---

# 네이버 리뷰 크롤러

네이버 스마트스토어·브랜드스토어 상품 리뷰를 백엔드 API로 직접 수집하는 전용 스킬. 일반 url-scraper로 시도하지 말고 이 스킬을 우선 사용한다.

## 왜 이 스킬이 따로 있는가

네이버 리뷰는 겉보기에 무한 스크롤 레이지 로딩이지만, 실제로는 단일 백엔드 API(`POST /n/v1/contents/reviews/query-pages`)를 페이지 단위로 호출하는 구조다. agent-browser로 스크롤하며 DOM을 긁는 방식은 1,000건 기준 30분이 걸리는 반면, 같은 페이지 컨텍스트에서 `fetch(credentials:'include')`로 API를 직접 치면 60초면 끝난다. 이 스킬은 그 경로를 표준화한다.

## 핵심 사실 (절대 까먹지 말 것)

1. **API 엔드포인트** (호스트가 도메인별로 다름):
   - `brand.naver.com/n/v1/contents/reviews/query-pages` (브랜드스토어)
   - `smartstore.naver.com/i/v1/contents/reviews/query-pages` (스마트스토어)
   둘 다 메서드 POST, body 형식 동일. **호스트는 페이지 host에 맞춰서** 호출해야 한다 (cross-origin 우회 회피).
2. **페이지 크기**: `pageSize: 20` (서버 강제 상한)
3. **두 개의 ID에 주의**:
   - `URL productNo` (URL에 보이는 ID, 예 `11071660183`) — SKU 노출 ID
   - `originProductNo` (API에 들어가는 ID, 예 `11019395358`) — 원본 상품 ID
   - **둘은 다르다.** 페이지 첫 로드 시 호출되는 `/n/v2/channels/<channelId>/products/<URL_productNo>?withWindow=false` 응답에서 `originProductNo`와 `checkoutMerchantNo` 둘 다 추출 가능.
4. **첨부 URL 필드**: `reviewAttaches[].attachUrl` (또는 `attachPath`). `originalUrl`/`thumbnailUrl`/`url` **없음**. 100% null로 나오면 필드명 확인 첫 의심.
5. **레이트 리밋**: 200ms 지연으로 1차는 통과, 2차에서 HTTP 429. **700ms 이상**이 안전. 429 발생 시 약 60초 쿨다운 필요.
6. **인증**: 일반 상품은 캡차/로그인 없이 페이지 1회 방문 후 같은 브라우저 컨텍스트에서 `credentials:'include'` 호출만으로 충분. 캡차가 뜨는 경우만 사용자에게 수동 해결 요청.
7. **정렬**: `REVIEW_CREATE_DATE_DESC` (최신순) 또는 `REVIEW_RANKING` (랭킹). 분석용으로는 최신순 기본.

## 워크플로우

### Step 1 — URL에서 도메인·productNo 추출, 기존 메모리 확인
```bash
python .claude/skills/naver-review-scraper/scripts/parse_url.py "<상품 URL>"
# → {"channel": "camelmount", "url_productNo": "11071660183"}
```
`output/naver.com/<channel>_<url_productNo>/` 폴더가 이미 있고 최근 실행 기록이 있으면, 사용자에게 "재수집인지 신규인지" 1줄로 묻는다.

### Step 2 — agent-browser로 페이지 1회 방문 (헤드 모드)
캡차 가능성을 사용자에게 미리 안내하고 `agent-browser --headed --session naver`로 URL을 연다. 캡차가 뜨면 사용자가 직접 해결.

### Step 3 — IDs 추출
페이지 로드 직후 in-page eval로 메타 추출:
```javascript
(async () => {
  const channelId = location.pathname.split('/')[1]; // "camelmount" 류는 채널명, 실제 channelId는 별도
  // 첫 로드 시 호출되는 product XHR로부터 추출
  // 또는 window 전역의 __APOLLO_STATE__ / __NEXT_DATA__ 내부 확인
})();
```
실전 권장: `agent-browser network requests --filter "products/.*?withWindow=false"` 결과에서 channelId·originProductNo·checkoutMerchantNo를 뽑는다. (`scripts/extract_ids.py` 참조)

### Step 4 — query-pages API 페이지네이션 호출
같은 브라우저 컨텍스트에서 `agent-browser eval --stdin`로 in-page fetch 루프 실행. **반드시 700ms 이상 지연**, 429 발생 시 4초·8초·12초 백오프. 한 호출에 30~50 페이지씩 배치하면 agent-browser eval 타임아웃(25s) 안에 안전하게 들어옴.

`scripts/fetch_reviews.js`를 동적 치환(__START__·__END__) 후 사용. 결과는 `output/naver.com/<channel>_<url_productNo>/_raw_<batch>.json`에 저장.

### Step 5 — 병합·중복 제거·xlsx 저장
```bash
python .claude/skills/naver-review-scraper/scripts/merge_and_save.py \
  --raw-dir output/naver.com/<channel>_<url_productNo> \
  --output output/naver.com/<channel>_<url_productNo>/<channel>_<model>_reviews_<YYYYMMDD_HHMMSS>.xlsx
```
- `id` 기준 dedupe
- 컬럼 13개 표준 출력 (리뷰ID·작성일시·평점·작성자·옵션·본문·리뷰형식·첨부수·재구매·리뷰타입·서비스타입·상품번호·주문번호)
- 본문 wrap_text, 평점/날짜 컬럼 너비 조정, autofilter + freeze panes

### Step 6 — 품질 게이트 (저장 전 사용자 확인)
저장 직전 사용자에게 보여줄 것:
- **총 행 수** vs 페이지에 표시된 리뷰 수 (불일치 시 누락 의심)
- **필드별 null/빈값 비율** (>20%는 [HIGH] 표시)
- **샘플 5행**: idx 0, 25%, 50%, 75%, last 위치
- **평점 분포** (1~5점 건수 + %)
- **날짜 범위** (oldest ~ newest)

사용자 OK 후 최종 파일명으로 저장.

### Step 7 — 도메인 메모리 갱신
`output/naver.com/<channel>_<url_productNo>/config.json`에 다음 실행을 위해 기록:
```json
{
  "url": "...",
  "channel": "camelmount",
  "url_productNo": "11071660183",
  "originProductNo": 11019395358,
  "checkoutMerchantNo": 500039600,
  "channelId": "2sWDvTkrxXNzVaXigFscH",
  "totalPages_at_last_run": 82,
  "rows_at_last_run": 1631,
  "delay_sec_used": 0.7,
  "last_success_at": "2026-04-23T16:15:00",
  "notes": "..."
}
```
다음 실행 시 이 파일이 있으면 Step 2(브라우저 방문)을 건너뛰고 바로 API 호출 가능 — 단, 세션 쿠키가 필요하므로 헤드리스라도 1회 방문은 권장.

## 후속 파이프라인 연동

수집 완료 후, 사용자가 "분류해줘"·"리뷰 분석"이라고 하면:
1. 이 스킬 결과 xlsx 또는 raw JSON을 `C:\Users\영유진\OneDrive\Desktop\박찬주\2026\리뷰 분석\.rawdata\` 또는 `<제품 폴더>/`로 복사
2. `.설정/classification_guide.md` 기준으로 80건/배치 병렬 에이전트 분류
3. `.설정/build_xlsx.py`로 4시트 분석 결과 생성 (집계 / 리뷰분류체계 / Claim상세 / 리뷰상세)
4. 필요 시 HTML+CSS 인사이트 리포트 → Playwright PDF 변환

상세 절차: `references/batch_classify_workflow.md` 참조.

## 4가지 원칙 (url-scraper 상속)

### 1. 구현 전에 생각하라
사용자 요구사항 해석을 1줄로 요약해 보여주고 진행. "최신 N개" 같이 애매한 표현은 정렬·기간을 명시.

### 2. 단순함 우선
`output/naver.com/<channel>_<url_productNo>/config.json`이 있으면 IDs 재추출 생략. agent-browser 구조 분석 절대 X — 이 도메인은 API 경로가 고정되어 있다.

### 3. 수술적 변경
`crawler_guide.md`는 append만. config.json은 IDs 같은 안정 정보만 갱신, 실행별 메타는 history 배열에 추가.

### 4. 목표 중심 실행
"잘 뽑혔다"는 (a) 페이지 표시 리뷰 수와 일치, (b) 중복 0, (c) 필드별 null 비율 <20%, (d) 사용자 샘플 5행 OK 4가지로 판단.

## 흔한 실패와 대응

| 증상 | 원인 | 대응 |
|------|------|------|
| 첫 페이지부터 401/403 | originProductNo·channelId 잘못 추출 | Step 3 재실행, network requests에서 정확한 ID 재확인 |
| 17페이지 부근부터 HTTP 429 | 지연 너무 짧음 | 60초 쿨다운 후 delay 1000ms로 재실행 |
| 첨부 URL 컬럼 100% 빈값 | 필드명을 `originalUrl`/`url`로 추측 | `attachUrl` 또는 `attachPath`로 변경 |
| totalPages × pageSize ≠ 페이지 표시 리뷰 수 | 일부 페이지 누락 (429를 조용히 넘김) | 페이지별 길이 검증, 부족한 페이지만 재호출 |
| 캡차 발생 | 브랜드/상품에 따라 봇 검출 강도 다름 | agent-browser headed 모드 + 사용자 수동 해결 |

## 참조

- `references/api_endpoint.md` — query-pages API 요청/응답 스키마, 모든 필드 의미
- `references/batch_classify_workflow.md` — 수집 → 80건/배치 병렬 분류 → xlsx 통합 → PDF 리포트 전 과정
- `references/troubleshooting.md` — 케이스별 해결책 누적 기록
- `scripts/parse_url.py` — URL 파서
- `scripts/extract_ids.py` — channelId·originProductNo·checkoutMerchantNo 추출
- `scripts/fetch_reviews.js` — in-page fetch 루프 템플릿 (agent-browser eval --stdin 입력)
- `scripts/merge_and_save.py` — 배치 병합 + 표준 xlsx 생성
