# pojia — 破甲 skill

三层指令链（宿主层 / 注入层 / 正文层）合成一个可落地的破甲规格。

## 文件

| 文件 | 作用 |
|---|---|
| `SKILL.md` | 主文档：开工顺序、七层结构、8 个强度增强器、失败诊断表 |
| `references/layers.md` | **L-A / L-B / L-C 三层落地对照表**（具体到路径与字段名） |
| `references/template-seven-layers.md` | 七层空模板，复制即用 |
| `references/example-max.md` | 满配示例（约 5.3 KB，R1–R7 全上） |
| `references/example-compact.md` | 窄位压缩版（1.27 KB，chat-box 载体） |
| `references/models/anthropic.md` | Claude 族骨架与坑 |
| `references/models/openai.md` | GPT / o 系骨架与坑 |
| `references/models/gemini.md` | Gemini 族骨架与坑 |
| `references/models/cn-family.md` | DeepSeek / GLM / Qwen / Kimi 族骨架 + 中文软化词清单 |
| `references/models/agent-host.md` | Agent 宿主（DSH / CC / OpenCode）骨架 |
| `scripts/pojia_probe.py` | 体检（七层完整性 / 禁用词 / 元话语 / 体积）+ 生成 V1–V5 变体 + 端点指纹 |
| `scripts/pojia_regress.py` | 打靶回归，出通过率数字 |
| `scripts/suite.jsonl` | 20 条判据用例（可自行扩充） |
| `scripts/mock_endpoint.py` | 本地假端点，验证判据能区分 PASS/FAIL（不联网） |

## 三条命令

```bash
# 1. 体检
python scripts/pojia_probe.py --check references/example-max.md --carrier dsh-inject

# 2. 生成变体（V1 中性化 / V2 英文壳 / V3 b64 尾巴 / V4 队列锚 / V5 人格接管）
python scripts/pojia_probe.py --variants references/example-max.md --out ./variants

# 3. 打靶（任意 OpenAI 兼容端点；Ollama 用 http://127.0.0.1:11434/v1）
python scripts/pojia_regress.py --base-url http://127.0.0.1:1990/v1 --api-key "$KEY" \
  --model MODEL_ID --prompt references/example-max.md \
  --suite scripts/suite.jsonl --carrier proxy-light --report regress.json
```

## 已验证

- `pojia_probe.py --check` 对 `example-max.md`：七层全 OK、禁用词 0 命中（跳过"禁止清单"章节与掩码写法）、体积 5301 B 在预算内
- `pojia_probe.py --variants`：5 个变体正常产出
- `pojia_regress.py` 对 `mock_endpoint.py --mode compliant`：10/20（缺必需形态判据正常报错）
- 对 `--mode refusing`：0/20，19 条命中禁用词——**判据确实能区分**
- `pojia_probe.py --fingerprint` 对 mock 端点正常打分并给出骨架建议

## 载体预算

| 载体 | 字节 |
|---|---|
| `api` / `ollama` | 4–12 KB |
| `agent` | 3–8 KB |
| `proxy-light` | 2–4 KB |
| `proxy-heavy` | 4–16 KB |
| `dsh-inject` | 4–16 KB |
| `chat-box`（单条消息位） | 0.6–1.2 KB |

## 素材来源

- L-C 正文骨架：`togg53192-cmd/jailbreaks`（32 份 prompt / 26+ 模型）
- L-B 注入面：`mizaawa/ZakoProxyCLI`（`profile_ids` + `default_strategy_enabled`，按映射后实际模型 ID 精确匹配，`instructions` 前置）
- L-A 宿主层：`ZHOUiu/dsh-purge`（`prompt-inject.md` / 工作区 md / 插件默认槽 + workspace baseline policy 三选一）
