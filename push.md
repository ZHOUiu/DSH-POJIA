# 推送到 GitHub（一步到位）

需要：GitHub Personal Access Token（含 `repo` 权限）。**只需要 token，其它不用给。**

## 用法

```powershell
# 把 ghp_xxx 换成你的 token（建议先 $env:GH_TOKEN 设好，别写进命令历史）
$env:GH_TOKEN = 'ghp_xxxxxxxxxxxxxxxxxxxx'
.\push.ps1
```

或指定仓库名/可见性：

```powershell
.\push.ps1 -RepoName 'DSH-POJIA' -Visibility private
.\push.ps1 -Owner 'your-name' -RepoName 'DSH-POJIA'
```

## 它会做什么

1. 校验 token（`GET /user`），读出真实用户名
2. 检查仓库是否已存在（`GET /repos/{owner}/{repo}`）
3. 不存在就创建（`POST /user/repos`），存在就复用
4. `git remote add origin https://<token>@github.com/<owner>/<repo>.git`
5. `git push -u origin main`
6. 打印仓库 URL，并把 remote 改回不含 token 的干净地址

## 失败排查

| 报错 | 原因 | 处理 |
|---|---|---|
| `401 Bad credentials` | token 过期/拼错 | 重新生成，注意别漏字符 |
| `403 Resource not accessible` | token 缺 `repo` 权限 | 重新签发，勾 `repo`（classic）或 `Contents: Read and write`（fine-grained） |
| `422 name already exists` | 同名仓库已在 | 换 `-RepoName`，或加 `-Owner` 指定账号 |
| `remote origin already exists` | 脚本重复跑 | 脚本已处理（先 remove 再加） |
| `push declined (protected)` | 目标分支受保护 | 换新仓库，或先在网页解开 main 保护 |
| `Recv failure: Connection was reset` | **直连 GitHub 被 RST（国内常见）** | 脚本会自动探测本地代理；不行就显式指定：`.\push.ps1 -Proxy 'http://127.0.0.1:7890'` |
| `Could not connect to server` (21s 超时) | 无代理且直连不通 | 开代理后重跑；`-NoProxy` 是强制直连的开关 |
| `Failed to connect ... 443` | 代理端口写错 | 确认 Clash/V2Ray 端口：7897 / 7890 / 10809 常见 |

## 实测记录（2026-11）

本机直连 `github.com:443` 能握手，但 `git push` 必被 reset：

```
fatal: unable to access 'https://github.com/.../': Recv failure: Connection was reset
```

走本地代理 7897 后一次通过。脚本已内置自动探测 + 3 次重试。
