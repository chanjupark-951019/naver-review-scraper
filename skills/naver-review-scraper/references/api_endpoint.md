# 네이버 리뷰 query-pages API 레퍼런스

## 엔드포인트

```
POST https://brand.naver.com/n/v1/contents/reviews/query-pages
Content-Type: application/json
```

스마트스토어(`smartstore.naver.com`)도 동일 백엔드. 호출은 항상 `brand.naver.com` 호스트로 가능 (CORS는 in-page fetch로 우회).

## 요청 바디

```json
{
  "checkoutMerchantNo": 500039600,
  "originProductNo": 11019395358,
  "page": 1,
  "pageSize": 20,
  "reviewSearchSortType": "REVIEW_CREATE_DATE_DESC"
}
```

| 필드 | 타입 | 설명 |
|------|------|------|
| `checkoutMerchantNo` | int | 가맹점 결제 번호. 페이지 메타에서 추출 |
| `originProductNo` | int | **원본 상품 번호**. URL의 productNo와 다름 |
| `page` | int | 1-based 페이지 번호 |
| `pageSize` | int | 최대 20 (서버 강제 상한) |
| `reviewSearchSortType` | enum | `REVIEW_CREATE_DATE_DESC` (최신순) / `REVIEW_RANKING` (랭킹) / `REVIEW_CREATE_DATE_ASC` / `REVIEW_SCORE_DESC` / `REVIEW_SCORE_ASC` |

## 응답 최상위 키

```json
{
  "contents": [...],
  "page": 1,
  "size": 20,
  "totalElements": 1631,
  "totalPages": 82,
  "sort": "...",
  "first": true,
  "last": false
}
```

## contents[] 항목 주요 필드

| 필드 | 타입 | 의미 |
|------|------|------|
| `id` | int | 리뷰 고유 ID (dedupe key) |
| `reviewScore` | int | 별점 1~5 |
| `reviewContent` | string | 본문 (개행 포함) |
| `createDate` | ISO datetime | 작성일시 (UTC+9 기준이지만 +00:00로 표기됨, 한국 시간으로 변환 필요) |
| `maskedWriterId` | string | 작성자 마스킹 ID (예 `dndu*****`) |
| `productOptionContent` | string | 옵션 텍스트 (예 `제품: SMB86W`) |
| `repurchase` | bool | 재구매 여부 |
| `reviewType` | enum | `NORMAL` / `MONTH` 등 |
| `reviewServiceType` | enum | `SELLBLOG` 등 |
| `reviewContentClassType` | enum | `TEXT` / `PHOTO` / `VIDEO` |
| `reviewAttaches[]` | array | 첨부 배열. **URL은 `attachUrl`** (또는 `attachPath`) |
| `productNo` | string | URL의 productNo |
| `productOrderNo` | string | 주문 번호 |
| `productName` | string | 상품명 |
| `eventTitle` | string | 이벤트 리뷰 제목 (대부분 빈값) |

## 헤더 요구사항

같은 origin(`brand.naver.com`) 페이지 컨텍스트에서 `fetch(url, {credentials: 'include'})`로 호출하면 쿠키·CSRF 자동 처리. 별도 헤더 불필요.

외부 컨텍스트(예 Python httpx)에서 호출하려면 페이지 방문 후 다음을 수동 주입:
- `Cookie`: 페이지 세션 전부
- `User-Agent`: 페이지 방문 시 사용한 UA와 동일
- `Referer`: 상품 페이지 URL
- `x-client-version`: 페이지의 정적 자산 빌드 버전 (선택)

권장은 **항상 in-page fetch**. 외부 호출은 차단 위험이 더 높다.

## 레이트 리밋 실측

| 지연 | 결과 |
|------|------|
| 150ms | 16~17페이지 부근에서 429 |
| 200ms | 1차 통과, 2차에서 429 |
| 500ms | 보통 통과하나 안정 보장 못 함 |
| **700ms** | **권장 — 안정** |
| 1000ms | 보수적 안전 |

429 발생 시 약 60초 쿨다운 후 재개 가능. 동일 IP 기준이므로 IP 변경으로 우회 가능하지만 권장 X.

## 두 개의 productNo

페이지 URL: `https://brand.naver.com/camelmount/products/11071660183`
→ `URL productNo` = `11071660183`

API에 들어가는 ID:
→ `originProductNo` = `11019395358`

이 둘이 다르다는 사실을 잊지 말 것. originProductNo는 페이지 첫 로드 시 호출되는 다음 XHR 응답에서 추출:
```
GET https://brand.naver.com/n/v2/channels/<channelId>/products/<URL_productNo>?withWindow=false
```

응답의 `originProductNo` 필드 또는 product detail의 다른 위치에 있음. 또한 페이지의 `__APOLLO_STATE__` / `__NEXT_DATA__`에도 포함됨.

## channelId

URL에 보이는 채널명(`camelmount`)과는 다른 별도의 식별자. 예: `2sWDvTkrxXNzVaXigFscH`.
페이지 첫 로드 XHR(`/n/v2/channels/<channelId>/...`)의 path 또는 페이지 전역 변수에서 추출.

## 정렬 옵션 비교

| 정렬 | 용도 |
|------|------|
| `REVIEW_CREATE_DATE_DESC` | **분석 기본**. 최신부터 |
| `REVIEW_CREATE_DATE_ASC` | 최초 출시일 ~ 시간순 분석 |
| `REVIEW_RANKING` | 페이지에 노출되는 BEST 리뷰 순서 (도움돼요·이미지 포함 가중) |
| `REVIEW_SCORE_DESC` | 5점만 보고 싶을 때 |
| `REVIEW_SCORE_ASC` | 1~2점 부정 리뷰 집중 분석 |

전수 수집이라면 정렬 무관 — 최신순(DESC)이 표준.
