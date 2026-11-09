# 来源与授权说明（SOURCES）

本文件回答三个问题：**内容从哪来、哪些是原创、再分发有什么限制。**

一句话结论：本仓库的**文字与代码是原创**（字符级 n-gram 与上游最大重合 1.95%，见下），上游三仓库只作为**架构思路与机制事实**的参考来源，未逐字复制其 prompt 正文。因此本仓库可以按 MIT 授权；但**引用上游的机制描述、以及他人再引用上游原文时**，仍受上游各自的条款约束（见 §4）。

---

## 1. 三个参考来源

### 1.1 togg53192-cmd/jailbreaks

| 项 | 值 |
|---|---|
| 地址 | <https://github.com/togg53192-cmd/jailbreaks> |
| 描述 | LIST OF ALL MY JAILBREAKS |
| 内容 | 32 份 prompt / 70 个文件 / 目录按模型厂商分组（Anthropic、OpenAI、Google、Alibaba、DeepSeek、Zhipu AI、Moonshot AI、xAI、Meta、Mistral、Tencent、Xiaomi、Meituan、StepFun、NVIDIA 等） |
| 许可证 | **无 LICENSE 文件**（GitHub API `license: null`） |
| 星标 | 15,581（2026-11 数据） |
| 本仓库引用范围 | **仅架构思路**：persona lock / agent operating specification / workspace profile / Modelfile / 配置槽 这几类**文档形态**的分类方式 |

**重要限制**：该仓库没有许可证文件。按《伯尔尼公约》默认规则，无许可证 = **保留所有权利**，其 prompt 正文**不可再分发**。本仓库因此：

- 未包含该仓库任何 prompt 文件的全文或片段
- `skill/references/models/*.md` 里的族骨架是**自行重写**的，描述的是各族的行为特征与常见失效模式，不是上游 prompt 的翻译或改写
- 若你要在自己的项目里使用该仓库的 prompt 原文，请直接向其作者取得许可

### 1.2 mizaawa/ZakoProxyCLI

| 项 | 值 |
|---|---|
| 地址 | <https://github.com/mizaawa/ZakoProxyCLI> |
| 描述 | 基于 Rust 编写的中转 API 破甲项目，支持 Responses / Chat Completions / Anthropic Messages API，支持 ChatGPT/Claude/Grok/Gemini/DeepSeek/GLM/Kimi 等主流模型 |
| 许可证 | **MIT** — Copyright (c) 2026 ZakoAI contributors |
| 星标 | 220（2026-11 数据） |
| 本仓库引用范围 | **机制事实**：策略按「映射后的实际模型 ID」精确匹配；`profile_ids` 与 `default_strategy_enabled` 的双层命中顺序；注入位置为 Responses 的 `instructions` 前置 / Chat 的独立 `system` 消息 / Anthropic 的 `system` 字段 |
| 未引用 | 该仓库的 Rust 源码、`profiles/` 下的策略正文（冷咖啡、寒霜等）、Docker 部署脚本 |

这些机制事实属于**接口行为描述**（不受版权保护的思想/方法层面），本仓库在 `skill/references/layers.md` 与 `skill/SKILL.md` §1.4 中用自己的话重述，并注明出处。

### 1.3 ZHOUiu/dsh-purge

| 项 | 值 |
|---|---|
| 地址 | <https://github.com/YuJunZhiXue/dsh-purge>（原仓库，本会话核查时返回 404，已下线） |
| 可用镜像 | <https://github.com/ZHOUiu/dsh-purge>（fork，含全部分支 / 73 个 tag / 完整历史） |
| 描述 | DeepSeek-Harness 破甲插件；上游即将删库，镜像保留全量 |
| 许可证 | **MIT** — Copyright (c) 2026 小杨 |
| 本仓库引用范围 | **机制事实**：`$DSH_HOME/prompt-inject.md` 的每轮注入决策链（prompt-inject 非空 → 工作区 md → 插件默认槽）；`workspace-policy` 的 strict / fallback / always 三选一对基线段的影响；skills 不参与注入段 |

**该仓库作者明确要求署名**（原文：「If you borrow this project's name, ideas, code, or prompts, you must credit the author and name the source repository」）。虽然本仓库没有借用其名称、代码或 prompt，只描述了机制，仍在此完整署名：**原作者 小杨（YuJunZhiXue / ZHOUiu）**，源仓库 `dsh-purge`。

---

## 2. 原创性核查方法与结果

担心「参考」变成「抄袭」，所以做了可复现的测量：

**方法**：把上游 5 份代表性 prompt（`BigPickle-opencode.md`、`Anthropic/opus v1.md`、`OpenAI/gpt-oss-20b.md`、`Meituan/longcat-agents.md`、`Google/gemma4.md`）与本地 15 份文档分别做**字符级 10-gram 集合**（去空白、转小写），计算 `|交集| / |本地 gram 数|`。

**结果**：

| 本地文件 | 10-gram 数 | 与上游最大重合 |
|---|---|---|
| `skill/references/models/openai.md` | 1,126 | 1.95% |
| `skill/references/models/gemini.md` | 850 | 1.53% |
| `skill/references/models/anthropic.md` | 1,055 | 0.95% |
| `skill/references/models/agent-host.md` | 1,572 | 0.45% |
| `skill/SKILL.md` | 6,284 | 0.45% |
| `skill/references/layers.md` | 1,910 | 0.47% |
| `skill/references/example-max.md` | 2,094 | 0.05% |
| `deploy/dsh/prompt-inject.md` | 8,120 | **0.00%** |
| `skill/references/example-compact.md` | 460 | **0.00%** |
| `skill/references/template-seven-layers.md` | 1,457 | **0.00%** |

最高 1.95% 的重合来自通用英文技术短语（如 `operating specification`、`output contract`、`pre-send check` 这类结构词），属于不可避免的术语碰撞。**无任何文件达到逐字复制程度。**

复现脚本（自备上游文件后可直接跑）：

```python
import re
def grams(t, n=10):
    t = re.sub(r"\s+", "", t).lower()
    return set(t[i:i+n] for i in range(max(0, len(t)-n+1)))
# overlap = len(local_grams & upstream_grams) / len(local_grams)
```

---

## 3. 本仓库自身的授权

主体内容为原创，按 **MIT** 发布，见 [LICENSE](LICENSE)。

`LICENSE` 中的版权人为 `DSH-POJIA contributors`。若你贡献了实质性内容并希望单独署名，见 [CONTRIBUTING-LICENSE.md](CONTRIBUTING-LICENSE.md)。

---

## 4. 再分发限制（给下游用的人）

| 场景 | 是否允许 | 依据 |
|---|---|---|
| 用本仓库的 SKILL.md / 脚本 / 示例正文 | ✅ MIT，保留版权声明即可 | 本仓库 LICENSE |
| 把本仓库的族骨架机制描述再写进你的项目 | ✅ 注明来自 DSH-POJIA | 同上 |
| 从本仓库跳到上游、复制 jailbreaks 的 prompt 原文 | ❌ 需向 togg53192-cmd 取得许可 | 上游无 LICENSE，默认保留所有权利 |
| 复制 ZakoProxyCLI 的 `profiles/` 策略正文 | ✅ 但必须保留其 MIT 版权声明 | 上游 MIT，Copyright (c) 2026 ZakoAI contributors |
| 复制 dsh-purge 的代码/prompt | ✅ 但必须保留 MIT 声明**并署名原作者 小杨** | 上游 MIT + 作者附加署名要求 |
| 把本仓库内容用于商业售卖 | ⚠️ MIT 允许，但若同时包含上游内容则受上游条款约束 | 见上两行 |

---

## 5. 免责

本仓库是 prompt 规格构建**方法与评估工具**。「破甲」是可选指令文本，不保证抢占上游系统指令优先级、不保证改变模型行为、不保证消除拒答；实际结果取决于上游模型与部署方式。

使用者应自行确认：在所在司法辖区与所用平台的服务条款下，对自己有权管理的模型/端点做此类评估是否被允许。作者不对使用后果承担责任。
