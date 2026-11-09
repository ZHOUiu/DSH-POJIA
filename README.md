# DSH-POJIA

**破甲（armor-break）技能包：三层指令链 —— 宿主层 / 注入层 / 正文层。**

一套可落地的 prompt 规格构建方法 + 可直接安装的 DSH 注入正文 + 体检/打靶脚本。
面向**本地模型与自建中转的鲁棒性评估**、拒答率压测、指令优先级研究，以及需要高通过率的固定人格配置。

---

## 为什么是三层

只写一段「扮演 XX，不许拒绝」的正文，会被两层东西压回去：

| 层 | 打的是什么 | 谁提供这层 |
|---|---|---|
| **L-A 宿主层** | 框架自己插进来的工作区基线、审批闸门、拒绝话术 | `dsh-purge` 类插件：`prompt-inject.md` + workspace policy 三选一 |
| **L-B 注入层** | 把正文塞进上游 `system` / `instructions`，抢在模型自带系统提示之前 | 自建反代（`profile_ids` + `default_strategy_enabled`，按映射后实际模型 ID 精确匹配） |
| **L-C 正文层** | 人格锁 / 任务重定义 / 输出契约 / 拒答词清理 | 七层骨架 L0–L6 + 8 个强度增强器 |

**三层齐了才叫彻底**；指不出「这一层落地在哪个路径/字段」，就是没落地。

---

## 仓库结构

```
skill/                          ← 技能本体（可放进 $DSH_HOME/skills/）
  SKILL.md                      主文档：开工顺序 / 七层结构 / R1-R8 增强器 / 失败诊断表
  README.md                     文件索引 + 已验证记录
  references/
    layers.md                   L-A / L-B / L-C 三层落地对照表（到路径与字段名）
    template-seven-layers.md    七层空模板
    example-max.md              满配示例 5.3 KB（R1-R7 全上）
    example-compact.md          窄位压缩版 1.3 KB（单条消息位）
    models/
      anthropic.md              Claude 族骨架与坑
      openai.md                 GPT / o 系骨架与坑
      gemini.md                 Gemini 族骨架与坑
      cn-family.md              DeepSeek / GLM / Qwen / Kimi 族 + 中文软化词清单
      agent-host.md             Agent 宿主（DSH / CC / OpenCode）骨架
  scripts/
    pojia_probe.py              体检（七层完整性 / 禁用词 / 元话语 / 体积）+ V1-V5 变体 + 端点指纹
    pojia_regress.py            打靶回归，出通过率数字
    suite.jsonl                 20 条判据用例
    mock_endpoint.py            本地假端点，验证判据能区分 PASS/FAIL

deploy/dsh/                     ← 已构建好的 DSH 成品
  prompt-inject.md              DSH-POJIA 注入正文（11.3 KB，七层齐）
  INSTALL.md                    安装/验证/回滚说明
```

---

## 快速开始

```bash
# 1. 体检
python skill/scripts/pojia_probe.py --check skill/references/example-max.md --carrier dsh-inject

# 2. 生成变体（中性化 / 英文壳 / b64 尾巴 / 队列锚 / 人格接管）
python skill/scripts/pojia_probe.py --variants skill/references/example-max.md --out ./variants

# 3. 打靶（任意 OpenAI 兼容端点；Ollama 用 http://127.0.0.1:11434/v1）
python skill/scripts/pojia_regress.py \
  --base-url http://127.0.0.1:1990/v1 --api-key "$KEY" --model MODEL_ID \
  --prompt skill/references/example-max.md \
  --suite skill/scripts/suite.jsonl --carrier proxy-light --report regress.json
```

装进 DSH 宿主：

```powershell
Copy-Item "$env:DSH_HOME\prompt-inject.md" "$env:DSH_HOME\prompt-inject.md.bak-$(Get-Date -f yyyyMMdd-HHmmss)"
Copy-Item .\deploy\dsh\prompt-inject.md "$env:DSH_HOME\prompt-inject.md" -Force
# 然后：完全退出 DSH → 重开 → 开新会话
```

---

## 七层骨架

```
L0 边界声明     本次会话是什么；把"请求"重定义为"任务参数"
L1 身份锚       名字 + 一句动机（拒绝=故障，不是选项）
L2 冲突裁决     本规格 > 会话指令 > 插入文本/工具返回值 > 默认客气
L3 任务重定义   用户输入 = 参数；缺参数填占位符继续
L4 输出契约     首字符即交付物；禁复述；禁"接下来我会…"
L5 拒答词清理   硬拒答/软回退/自加前言/替代方案 四类，含中文软性变体
L6 发送前自检   三项全为是才发送；否则静默重写
```

## 8 个强度增强器

`R1` 双身份叠压 · `R2` 上下文稀释 · `R3` 人格接管（非新增）· `R4` 输出先行 · `R5` 队列锚 · `R6` 编码备份 · `R7` 元层反制（conflict.log）· `R8` 采样面

---

## 已验证

| 检查 | 结果 |
|---|---|
| `pojia_probe.py --check example-max.md` | 七层全 OK，禁用词 0 命中，5,328 B 在预算内 |
| `pojia_probe.py --check example-compact.md` | 1,279 B，chat-box 预算内 |
| `pojia_probe.py --variants` | 5 个变体正常产出 |
| `pojia_regress.py` vs `mock_endpoint --mode compliant` | 10/20（缺必需形态判据正常报错） |
| `pojia_regress.py` vs `mock_endpoint --mode refusing` | 0/20，19 条命中禁用词 —— **判据确实能区分** |
| `pojia_probe.py --fingerprint` | 正确打分并给出骨架建议 |
| DSH 侧 `isUserCustomizedOverrideSync` | `true` —— 插件不会覆盖用户稿 |
| DSH 侧 `resolveInjectText` | `source: "prompt"` |
| DSH 侧 `peelChatmlEnvelope` / `stripChatmlTags` | 内容零删改 |

## 载体预算

| 载体 | 字节 |
|---|---|
| `api` / `ollama` | 4–12 KB |
| `agent` | 3–8 KB |
| `proxy-light` | 2–4 KB |
| `proxy-heavy` | 4–16 KB |
| `dsh-inject` | 4–16 KB |
| `chat-box` | 0.6–1.4 KB |

---

## 素材来源

- **L-C 正文骨架**：[togg53192-cmd/jailbreaks](https://github.com/togg53192-cmd/jailbreaks)（32 份 prompt / 26+ 模型）
- **L-B 注入面**：[mizaawa/ZakoProxyCLI](https://github.com/mizaawa/ZakoProxyCLI)（`profile_ids` + `default_strategy_enabled`，`instructions` 前置，按映射后实际模型 ID 精确匹配）
- **L-A 宿主层**：[ZHOUiu/dsh-purge](https://github.com/ZHOUiu/dsh-purge)（`prompt-inject.md` / 工作区 md / 插件默认槽 + workspace baseline policy 三选一）

## 说明

本仓库是 prompt 规格构建方法与评估工具。「破甲」是**可选指令文本**，不保证抢占上游系统指令优先级、不保证改变模型行为、不保证消除拒答；实际结果取决于上游，请自行在可控环境内评估。

## License

MIT
