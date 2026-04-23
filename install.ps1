# naver-review-scraper 설치 스크립트 (Windows PowerShell)
# 사용:
#   iwr -useb https://raw.githubusercontent.com/chanjupark-951019/naver-review-scraper/main/install.ps1 | iex
#
# 프로젝트 단위로 설치하려면:
#   $env:NRS_TARGET = ".\.claude\skills"; iwr -useb https://raw.githubusercontent.com/chanjupark-951019/naver-review-scraper/main/install.ps1 | iex

$ErrorActionPreference = 'Stop'
$SkillName = 'naver-review-scraper'
$Repo = 'https://github.com/chanjupark-951019/naver-review-scraper.git'

if ($env:NRS_TARGET) {
    $Target = $env:NRS_TARGET
} else {
    $Target = Join-Path $HOME '.claude\skills'
}

Write-Host "Target: $Target"
New-Item -ItemType Directory -Force -Path $Target | Out-Null

$Tmp = Join-Path $env:TEMP "nrs_$([guid]::NewGuid().Guid.Substring(0,8))"
try {
    Write-Host "Cloning..."
    git clone --depth 1 --quiet $Repo "$Tmp\repo"

    $Dest = Join-Path $Target $SkillName
    if (Test-Path $Dest) {
        Write-Host "Removing existing $Dest"
        Remove-Item -Recurse -Force $Dest
    }

    Copy-Item -Recurse "$Tmp\repo\skills\$SkillName" $Target

    Write-Host ""
    Write-Host "Installed: $Dest" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "  1. Claude Code 재시작 (필요한 경우)."
    Write-Host "  2. 채팅창에 네이버 상품 URL을 그대로 던지면 자동 트리거됩니다:"
    Write-Host "     예) https://brand.naver.com/<채널>/products/<번호> 리뷰 수집해줘"
    Write-Host ""
    Write-Host "필요 환경:"
    Write-Host "  - agent-browser CLI: npm i -g agent-browser && agent-browser install"
    Write-Host "  - Python 3.x + openpyxl: pip install openpyxl"
} finally {
    if (Test-Path $Tmp) {
        Remove-Item -Recurse -Force $Tmp
    }
}
