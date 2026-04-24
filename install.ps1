# naver-review-scraper 설치 스크립트 (Windows PowerShell)
# 사용:
#   iwr -useb https://raw.githubusercontent.com/chanjupark-951019/naver-review-scraper/main/install.ps1 | iex

$ErrorActionPreference = 'Stop'
$SkillName = 'naver-review-scraper'
$Repo = 'https://github.com/chanjupark-951019/naver-review-scraper.git'
$Target = if ($env:NRS_TARGET) { $env:NRS_TARGET } else { Join-Path $HOME '.claude\skills' }

Write-Host "═══════════════════════════════════════════════════════"
Write-Host "  naver-review-scraper 설치"
Write-Host "═══════════════════════════════════════════════════════"

# [1/5] 환경 점검
Write-Host ""
Write-Host "[1/5] 환경 점검..."
$missing = @()
foreach ($cmd in @('node','npm','git','python')) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        $missing += $cmd
    }
}
if ($missing.Count -gt 0) {
    Write-Host "  X 다음이 먼저 설치되어야 합니다:" -ForegroundColor Red
    foreach ($m in $missing) {
        $url = switch ($m) {
            'node'   { 'https://nodejs.org' }
            'npm'    { 'https://nodejs.org (Node.js와 함께 설치)' }
            'git'    { 'https://git-scm.com' }
            'python' { 'https://python.org' }
        }
        Write-Host "    - $m  ($url)"
    }
    Write-Host "  설치 후 새 PowerShell 창을 열고 다시 실행해주세요."
    exit 1
}
Write-Host "  OK node $(node --version), npm $(npm --version), git, python"

# [2/5] 시스템 Chrome 감지
Write-Host ""
Write-Host "[2/5] 시스템 Chrome 감지..."
$chromePaths = @(
    "C:\Program Files\Google\Chrome\Application\chrome.exe",
    "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
    (Join-Path $env:LOCALAPPDATA 'Google\Chrome\Application\chrome.exe')
)
$ChromePath = $null
foreach ($p in $chromePaths) {
    if (Test-Path $p) { $ChromePath = $p; break }
}

if ($ChromePath) {
    Write-Host "  OK 시스템 Chrome 발견: $ChromePath" -ForegroundColor Green
    Write-Host "  -> agent-browser install (Chromium 200MB 다운로드)을 건너뜁니다."
} else {
    Write-Host "  ! 시스템 Chrome을 찾지 못했습니다." -ForegroundColor Yellow
    Write-Host "  -> agent-browser install을 실행합니다 (약 5~15분 소요, ~200MB 다운로드)"
}

# [3/5] agent-browser 설치
Write-Host ""
Write-Host "[3/5] agent-browser CLI 글로벌 설치..."
npm install -g agent-browser
Write-Host "  OK agent-browser installed"

if (-not $ChromePath) {
    Write-Host ""
    Write-Host "[3.5/5] Chromium 다운로드 (시간이 걸립니다, 진행 중...)"
    agent-browser install
}

# [4/5] Python 패키지
Write-Host ""
Write-Host "[4/5] Python 패키지 설치..."
python -m pip install --quiet openpyxl
Write-Host "  OK openpyxl"

# [5/5] 스킬 클론·복사
Write-Host ""
Write-Host "[5/5] 스킬 설치..."
New-Item -ItemType Directory -Force -Path $Target | Out-Null
$Tmp = Join-Path $env:TEMP "nrs_$([guid]::NewGuid().Guid.Substring(0,8))"
try {
    git clone --depth 1 --quiet $Repo "$Tmp\repo"
    $Dest = Join-Path $Target $SkillName
    if (Test-Path $Dest) { Remove-Item -Recurse -Force $Dest }
    Copy-Item -Recurse "$Tmp\repo\skills\$SkillName" $Target
    Write-Host "  OK $Dest" -ForegroundColor Green
} finally {
    if (Test-Path $Tmp) { Remove-Item -Recurse -Force $Tmp }
}

# 환경변수 안내 + 자동 설정
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════"
Write-Host "  설치 완료" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════"
if ($ChromePath) {
    Write-Host ""
    Write-Host "▸ 시스템 Chrome 환경변수를 영구 설정합니다 (사용자 스코프):"
    [Environment]::SetEnvironmentVariable('AGENT_BROWSER_EXECUTABLE_PATH', $ChromePath, 'User')
    Write-Host "    AGENT_BROWSER_EXECUTABLE_PATH = $ChromePath"
    Write-Host "  → 새 PowerShell/cmd 창부터 적용됩니다."
}
Write-Host ""
Write-Host "▸ Claude Code를 재시작하면 자동으로 트리거됩니다."
Write-Host "▸ 사용: 채팅창에 'https://brand.naver.com/<채널>/products/<번호> 리뷰 수집해줘'"
