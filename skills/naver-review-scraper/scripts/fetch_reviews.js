// agent-browser eval --stdin 입력 템플릿.
// 사용 전 다음 placeholder를 sed로 치환:
//   __HOST__                'brand.naver.com/n' (브랜드스토어) 또는 'smartstore.naver.com/i' (스마트스토어)
//   __ORIGIN_PRODUCT_NO__   originProductNo (int)
//   __CHECKOUT_MERCHANT_NO__ checkoutMerchantNo (int)
//   __START__               시작 페이지 (1-based, int)
//   __END__                 종료 페이지 (inclusive, int) — 모르면 totalPages를 안 잡고 끝까지 시도
//   __SORT__                'REVIEW_CREATE_DATE_DESC' 등
//   __DELAY_MS__            페이지 간 지연 (700 권장)
//
// 핵심: page > totalPages면 contents=[]가 와도 정상이므로 종료. 빈 응답에는 retry 후 포기.

(async () => {
  const out = [];
  let totalPages = null;
  for (let p = __START__; p <= __END__; p++) {
    let j = null;
    let attempts = 0;
    while (attempts < 5) {
      try {
        const res = await fetch('https://__HOST__/v1/contents/reviews/query-pages', {
          method: 'POST',
          credentials: 'include',
          headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
          body: JSON.stringify({
            checkoutMerchantNo: __CHECKOUT_MERCHANT_NO__,
            originProductNo: __ORIGIN_PRODUCT_NO__,
            page: p,
            pageSize: 20,
            reviewSearchSortType: '__SORT__'
          })
        });
        if (res.status === 429) {
          attempts++;
          await new Promise(r => setTimeout(r, 4000 * attempts));
          continue;
        }
        const text = await res.text();
        if (!text || text.length < 10) {
          attempts++;
          await new Promise(r => setTimeout(r, 2000));
          continue;
        }
        j = JSON.parse(text);
        break;
      } catch (e) {
        attempts++;
        await new Promise(r => setTimeout(r, 2000));
      }
    }
    if (!j) return {error: 'failed after retries', page: p, fetched: out.length, totalPages};
    if (totalPages === null) totalPages = j.totalPages;
    // Graceful end: page beyond totalPages or empty contents
    if (totalPages !== null && p > totalPages) break;
    if (!j.contents || j.contents.length === 0) break;
    for (const r of j.contents) {
      const a = r.reviewAttaches || [];
      out.push({
        id: r.id,
        score: r.reviewScore,
        date: r.createDate,
        writer: r.maskedWriterId,
        option: r.productOptionContent || '',
        content: r.reviewContent || '',
        repurchase: r.repurchase,
        reviewType: r.reviewType,
        reviewServiceType: r.reviewServiceType,
        reviewContentClassType: r.reviewContentClassType,
        attachCount: a.length,
        firstAttachUrl: a[0]?.attachUrl || a[0]?.attachPath || '',
        allAttachUrls: a.map(x => x.attachUrl || x.attachPath).filter(Boolean).join(' | '),
        productNo: r.productNo,
        productOrderNo: r.productOrderNo,
        productName: r.productName
      });
    }
    await new Promise(r => setTimeout(r, __DELAY_MS__));
  }
  return {totalPages, fetched: out.length, items: out};
})();
