# push.ps1 — 建仓库 + 推送，一步到位
#   $env:GH_TOKEN = 'ghp_xxx'; .\push.ps1
#   .\push.ps1 -RepoName 'DSH-POJIA' -Visibility private
param(
    [string]$Owner,
    [string]$RepoName = 'DSH-POJIA',
    [ValidateSet('public', 'private')][string]$Visibility = 'public',
    [string]$Description = 'Armor-break prompt skill: three-layer instruction chain (host / injection / payload) with probe + regression scripts.'
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Token = $env:GH_TOKEN
if (-not $Token) { throw '缺少 $env:GH_TOKEN。先设: $env:GH_TOKEN = ''ghp_xxx''' }

function Api {
    param([string]$Method, [string]$Path, $Body)
    $h = @{
        Authorization          = "Bearer $Token"
        Accept                 = 'application/vnd.github+json'
        'X-GitHub-Api-Version' = '2022-11-28'
        'User-Agent'           = 'DSH-POJIA-push'
    }
    $args = @{ Uri = "https://api.github.com$Path"; Headers = $h; Method = $Method; TimeoutSec = 30 }
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
Write-Host '      ok'

# 5. 推送
Write-Host '[5/5] push -> main ...'
git -C $Root push -u origin main 2>&1 | ForEach-Object { Write-Host "      $_" }
if ($LASTEXITCODE -ne 0) { throw "git push 失败（exit $LASTEXITCODE）" }

# 洗掉 remote 里的 token
git -C $Root remote set-url origin "https://github.com/$Owner/$RepoName.git"

Write-Host ''
Write-Host '========================================'
Write-Host "  完成: $($repo.html_url)"
Write-Host "  clone: git clone https://github.com/$Owner/$RepoName.git"
Write-Host '========================================'
