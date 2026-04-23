#!/usr/bin/env python3
"""네이버 상품 URL을 파싱해 channel과 url_productNo 추출.

지원 URL 형태:
- https://brand.naver.com/<channel>/products/<productNo>
- https://smartstore.naver.com/<channel>/products/<productNo>
- https://m.smartstore.naver.com/<channel>/products/<productNo>
- https://shopping.naver.com/window-products/style/<productNo>?... (일부)
"""
import sys
import json
import re
from urllib.parse import urlparse


def parse(url: str) -> dict:
    u = urlparse(url)
    host = u.hostname or ''
    path = u.path

    m = re.match(r'^/([^/]+)/products/(\d+)', path)
    if m:
        channel, product_no = m.group(1), m.group(2)
        return {
            'host': host,
            'channel': channel,
            'url_productNo': product_no,
            'kind': 'brand' if 'brand.naver' in host else 'smartstore' if 'smartstore' in host else 'unknown',
            'normalized_url': f'https://{host}{path}',
        }

    # window-products fallback
    m = re.match(r'^/window-products/[^/]+/(\d+)', path)
    if m:
        return {
            'host': host,
            'channel': None,
            'url_productNo': m.group(1),
            'kind': 'shopping-window',
            'normalized_url': url,
        }

    raise ValueError(f'Unsupported URL: {url}')


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print('usage: parse_url.py <URL>', file=sys.stderr)
        sys.exit(2)
    print(json.dumps(parse(sys.argv[1]), ensure_ascii=False, indent=2))
