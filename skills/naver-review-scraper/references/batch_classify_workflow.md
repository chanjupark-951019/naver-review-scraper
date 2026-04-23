# 수집 → claim 단위 분류 → xlsx + PDF 리포트 전 과정

이 스킬로 리뷰를 수집한 뒤, 곧바로 분류·리포트 단계로 이어지는 표준 절차다. 이번 세션(SMB86W 1,631건)에서 검증된 흐름을 그대로 옮겼다.

## Phase A — 수집 (이 스킬)
산출물: `output/naver.com/<channel>_<id>/<channel>_<model>_reviews_<TS>.xlsx` + `_raw_merged.json`

## Phase B — 분석 폴더 세팅
```
C:\Users\영유진\OneDrive\Desktop\박찬주\2026\리뷰 분석\<제품명>\
├── 배치리뷰\        batch_NN_reviews_<YYMMDD_YYMMDD>.json
├── 분석결과\        batch_NN_results_<YYMMDD_YYMMDD>.json + all_claims_<...>.json
├── manifest.json   배치 분할 메타
└── <제품명>_<YYMMDD_YYMMDD>_리뷰분석_결과.xlsx
```

## Phase C — 배치 분할
- 기준 배치 크기: **80건/배치** (이번 세션 검증값. 100건도 가능하지만 80이 정확도와 속도의 균형점)
- 1,631건 → 21배치 (20×80 + 1×31)
- 균등 분배가 핵심: 마지막 배치만 짧게, 나머지는 동일 크기

배치 JSON 행 형식:
```json
{
  "review_id": 1, "date": "26.04.23.", "rating": "5",
  "writer": "dndu*****", "option": "제품: SMB86W",
  "content": "...", "is_month_review": false
}
```

`createDate` (ISO) → `YY.MM.DD.` 변환 필수.

## Phase D — 병렬 에이전트 분류
- N개 배치 = N개 `general-purpose` 에이전트, **모두 한 번의 메시지에서 동시 발사** (`run_in_background: true`)
- 각 에이전트 프롬프트 핵심:
  1. `c:\Users\영유진\OneDrive\Desktop\박찬주\2026\리뷰 분석\.설정\classification_guide.md` 전체 Read (요약 금지)
  2. 자기 배치 JSON Read
  3. 각 review를 claim unit으로 분절·분류 (sentiment 4종, topic_lv1 8종, topic_lv2, target)
  4. 결과 JSON 배열을 자기 출력 경로에 Write
  5. "배치 NN 완료: claim N개, 감성 분포 긍/부/중/건 = a/b/c/d" 한 줄 보고

**해석 일관성 핵심 규칙** (절대 빠뜨리지 말 것):
- topic_lv2 전환 시점에서만 분절
- 단순 인사/총평/감사는 별도 claim X
- 건의 vs 독자 대상 발언 구분 (회사 요청만 건의)
- 부정의 부정 = 긍정
- 가격 "비싸지만 잘 샀다" → 부정 1건
- topic_lv1은 8개 정확히 (디자인/안정성/편의성/설치조립/품질/배송서비스/가격/기타)
- "한 달 사용 후기"의 [이전리뷰: ...] 부분 분석 제외

## Phase E — 검증·통합
모든 배치 완료 후:
```python
# 1. 병합
all_claims = []
for i in range(1, N+1):
    all_claims.extend(json.load(open(f'분석결과/batch_{i:02d}_results_<TS>.json')))

# 2. 검증
expected_ids = set(range(1, total_reviews+1))
covered = set(c['review_id'] for c in all_claims)
missing = expected_ids - covered  # 비어 있어야 함

# 3. 필드 누락 체크 — 일부 에이전트가 sentiment 누락하고 rating에 sentiment 값 넣는 경우 발생
SENTIMENT_VALUES = {'긍정','부정','중립','건의'}
for c in all_claims:
    if 'sentiment' not in c:
        if c.get('rating') in SENTIMENT_VALUES:
            c['sentiment'] = c['rating']
            c['rating'] = id_to_rating[c['review_id']]  # 원본에서 복구
        else:
            c['sentiment'] = '중립'  # fallback
```

**자주 나오는 에이전트 출력 오류 1개** (이번 세션에서 21배치 중 5배치, 9건 발생):
> rating 필드 자리에 sentiment 값(긍정/부정/중립/건의)이 들어가고 원래 별점이 누락됨.

발견 시 위 패치 코드로 복구.

## Phase F — xlsx 생성
표준 빌드 스크립트 사용:
```bash
python "C:\Users\영유진\OneDrive\Desktop\박찬주\2026\리뷰 분석\.설정\build_xlsx.py" \
  --claims 분석결과/all_claims_<TS>.json \
  --reviews_dir 배치리뷰 \
  --output <제품명>_<TS>_리뷰분석_결과.xlsx
```
4시트: 집계 / 리뷰분류체계 / Claim상세(감성색상) / 리뷰상세

## Phase G — PDF 인사이트 리포트 (선택)
HTML+CSS로 작성 → Playwright `page.pdf()`로 변환.

레이아웃 원칙:
- A4 마진 11mm, 본문 9.5pt, line-height 1.4
- KPI 카드 5장(총리뷰 / 긍·부·중·건 비율) → Strength Map → 만족 주제별 상세 → 불만족 주제별 상세 → 건의 분포 → 한달 사용 후기 → 종합
- **각 주제 = `<section class="section">`** + CSS `page-break-inside: avoid`
- 폰트: Pretendard 또는 맑은 고딕
- 색상 톤: 긍정 #16a34a, 부정 #dc2626, 중립 #94a3b8, 건의 #f59e0b

## 성능 기준값 (이번 세션 측정)

| 단계 | 시간 |
|------|------|
| API 수집 (1,631건, 82페이지, 700ms 지연) | ~70초 |
| 배치 21개 병렬 분류 | ~5분 (가장 느린 배치 5분 30초) |
| 통합·xlsx | <10초 |
| HTML→PDF | <5초 |
| **총** | ~7분 |

비교: agent-browser 스크롤 + DOM 추출로 같은 양 수집 시 약 30분 (5배 느림).
