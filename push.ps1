# push.ps1 — 建仓库 + 推送，一步到位
#   $env:GH_TOKEN = 'ghp_xxx'; .\push.ps1
#   .\push.ps1 -RepoName 'DSH-POJIA' -Visibility private
param(
    [string]$Owner,
    [string]$RepoName = 'DSH-POJIA',
    [ValidateSet('public', 'private')][string]$Visibility = 'public',
    [string]$Description = 'Armor-break prompt skill: three-layer instruction chain (host / injection / payload) with probe + regression scripts.',
    # 国内直连 GitHub 常被 reset：自动探测本地代理；设 -NoProxy 强制直连
    [string]$Proxy,
    [switch]$NoProxy
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Token = $env:GH_TOKEN
if (-not $Token) { throw '缺少 $env:GH_TOKEN。先设: $env:GH_TOKEN = ''ghp_xxx''' }

# 0. 代理探测：直连常被 reset，有本地代理就走代理（API 和 git 用同一个）
$ProxyUrl = ''
if (-not $NoProxy) {
    if ($Proxy) {
        $ProxyUrl = $Proxy
    } else {
        foreach ($p in 7897, 7890, 10809, 1080, 10808, 2080, 8080) {
            if (Test-NetConnection 127.0.0.1 -Port $p -InformationLevel Quiet -WarningAction SilentlyContinue) {
                $ProxyUrl = "http://127.0.0.1:$p"
                break
            }
        }
    }
}
if ($ProxyUrl) { Write-Host "      proxy: $ProxyUrl" } else { Write-Host '      proxy: 直连' }

function Api {
    param([string]$Method, [string]$Path, $Body)
    $h = @{
        Authorization          = "Bearer $Token"
        Accept                 = 'application/vnd.github+json'
        'X-GitHub-Api-Version' = '2022-11-28'
        'User-Agent'           = 'DSH-POJIA-push'
    }
    $args = @{ Uri = "https://api.github.com$Path"; Headers = $h; Method = $Method; TimeoutSec = 30 }
    if ($ProxyUrl) { $args.Proxy = $ProxyUrl }
    if ($Body) {
        $args.Body = ($Body | ConvertTo-Json -Depth 6)
        $args.ContentType = 'application/json; charset=utf-8'
    }
    Invoke-RestMethod @args
}

# 1. 校验 token
Write-Host '[1/5] 校验 token ...'
try {
    $me = Api GET '/user'
} catch {
    throw "token 无效或网络不通: $($_.Exception.Message)"
}
if (-not $Owner) { $Owner = $me.login }
Write-Host "      OK  -> $($me.login)  (plan: $($me.plan.name))"

# 2. 仓库是否存在
Write-Host "[2/5] 检查仓库 $Owner/$RepoName ..."
$exists = $true
try { $repo = Api GET "/repos/$Owner/$RepoName" } catch { $exists = $false }

# 3. 不存在则创建
if (-not $exists) {
    Write-Host '[3/5] 创建仓库 ...'
    $body = @{
        name        = $RepoName
        description = $Description
        private     = ($Visibility -eq 'private')
        has_issues  = $true
        has_wiki    = $false
        auto_init   = $false
    }
    try {
        $repo = Api POST '/user/repos' $body
        Write-Host "      created -> $($repo.html_url)"
    } catch {
        $msg = $_.ErrorDetails.Message
        if ($msg -match 'already exists') {
            Write-Host '      同名仓库已存在，改为复用'
            $repo = Api GET "/repos/$Owner/$RepoName"
        } else {
            throw "创建失败: $msg"
        }
    }
} else {
    Write-Host "      已存在 -> $($repo.html_url)（复用，追加推送）"
}

# 4. 配 remote（带 token，仅存在于本地 .git/config 的这一次 push）
Write-Host '[4/5] 配置 remote ...'
$authUrl = "https://$Token@github.com/$Owner/$RepoName.git"
git -C $Root remote remove origin 2>$null
git -C $Root remote add origin $authUrl
if ($ProxyUrl) {
    git -C $Root config http.proxy $ProxyUrl
    git -C $Root config https.proxy $ProxyUrl
}
git -C $Root config http.version HTTP/1.1
Write-Host '      ok'

# 5. 推送（直连被 reset 时自动重试一次）
Write-Host '[5/5] push -> main ...'
$pushed = $false
foreach ($attempt in 1..3) {
    git -C $Root push -u origin main 2>&1 | ForEach-Object { Write-Host "      $_" }
    if ($LASTEXITCODE -eq 0) { $pushed = $true; break }
    if ($attempt -lt 3) {
        Write-Host "      第 $attempt 次失败，2s 后重试 ..."
        Start-Sleep -Seconds 2
    }
}
if (-not $pushed) {
    throw "git push 失败（3 次均未成功）。若报 Connection was reset，说明直连被墙：确认本地代理已开，或 .\push.ps1 -Proxy 'http://127.0.0.1:7890'"
}

# 洗掉 remote 里的 token
git -C $Root remote set-url origin "https://github.com/$Owner/$RepoName.git"

Write-Host ''
Write-Host '========================================'
Write-Host "  完成: $($repo.html_url)"
Write-Host "  clone: git clone https://github.com/$Owner/$RepoName.git"
Write-Host '========================================'
