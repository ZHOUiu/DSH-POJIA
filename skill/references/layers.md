# 三层落地对照表（L-A / L-B / L-C 具体落哪）

一个"彻底"的破甲，三层都要能指出**一个真实路径或一个真实字段**。指不出来就是没落地。

## L-A 宿主层（Host）

| 宿主 | 落地位置 | 生效动作 | 不生效的常见错法 |
|---|---|---|---|
| DSH（desktop / web） | `$DSH_HOME/prompt-inject.md`（运行时文件） | 完全退出 → 重开 → Clean 页 Apply → 重启 → **开新会话** | 只装了插件没点 Apply；点完没重启；重启后接着旧会话 |
| DSH 规则库 | `$DSH_HOME/rules/*.md`，面板 Enable 后写入 `prompt-inject.md` | 同上 | 写了文件但没 Enable |
| DSH 工作区 md | 当前工作目录根的 `AGENTS.md` / `CLAUDE.md` | policy 为 `fallback` 时生效 | 文件为空；不在当前 cwd；policy 是 `always`（基线仍追加） |
| DSH workspace policy | 面板三选一 strict / fallback / always | 立即影响下一轮 | 用 `always` 又想丢基线（矛盾） |
| DSH skills | `$DSH_HOME/skills/<id>/SKILL.md` | 匹配到就加载 | 以为 skill 会替代 prompt 注入 |
| Claude Code | `--append-system-prompt` / 项目 `CLAUDE.md` | 启动时 | 写在别的项目目录 |
| OpenCode | `~/.config/opencode/AGENTS.md`（全局）或项目根 | 启动时 | 全局与项目同时写但内容冲突 |

**DSH 每轮决策链（记住这个顺序，改错层就白改）**：
```
prompt-inject.md 非空 ? → 用它
否则 → 当前目录勾选的 md 非空 ? → 用它
否则 → 插件加密默认槽
之后过 policy：strict 丢基线 / fallback（有 A 或 B 就丢）/ always 保留基线
```

## L-B 注入层（Injection）

| 通道 | 字段 | 顺序 | 备注 |
|---|---|---|---|
| OpenAI Responses | `instructions` | 在 `input` 之前 | 字符串；优先级高于 input 内的 system |
| Chat Completions | `messages[0]`，role=`system` | 第一项 | 不要塞在 user 里 |
| Anthropic Messages | 顶层 `system` | 可为数组分块，块序即优先序 | operating_spec 放第一块 |
| 自建反代（ZakoAI 形态） | 策略正文，前置到 `instructions` / 独立 `system` 消息 / `system` 字段 | 选中策略在前，客户端原指令保留在后 | 按**映射后实际模型 ID** 精确匹配，不系列通配 |

**反代侧的可控面（这是三层里最彻底的一层）**：
```
profiles/<策略名>/<精确模型ID>.md     ← 正文
profiles/<策略名>/SOURCE.json        ← 来源哈希、选段行号，便于复现
每把客户端 key：profile_ids[] + default_strategy_enabled(bool)
命中逻辑：专用策略优先 → 未命中看默认开关 → 都关则不注入
体积：轻量策略 ~2 KB；重策略 60 KB+ 会顶上下文、拖首 token
```

**必须写进交付说明的一句**：破甲是**可选指令文本**，不保证抢占上游系统指令优先级、不保证改变模型行为、不保证消除拒答；实际结果取决于上游。

## L-C 正文层（Payload）

| 载体 | 文件形态 | 体积预算 |
|---|---|---|
| 直连 API | 单文件 `system.md` | 4–12 KB |
| 本地 Agent | `AGENTS.md`（含工具清单 + 队列锚） | 3–8 KB |
| Ollama | `Modelfile.pojia`（`FROM` + `PARAMETER` + `SYSTEM """…"""`） | 4–12 KB |
| 反代轻量策略 | `profiles/<name>/<model>.md` | 2–4 KB |
| 反代重策略 | 同上 | ≤ 16 KB（中文族）/ ≤ 32 KB（英族） |
| DSH `prompt-inject.md` | 单文件 | 4–16 KB |
| 单条消息位（网页版） | 压缩版 L0+L1+L2+L4+L5 | ≤ 1.2 KB |

## 三层齐了的判定（交付前逐条打勾）

- [ ] **L-A**：能说出具体路径 / 开关名，以及"改完怎么让它生效"的三步
- [ ] **L-B**：能说出注入字段名 + 顺序（正文在前还是在后）
- [ ] **L-C**：七层齐全（用 `scripts/pojia_probe.py --check` 验）
- [ ] **体积**：在对应载体的预算内
- [ ] **回归**：跑过 `scripts/pojia_regress.py`，有通过率数字
- [ ] **回滚**：旧版备份留了，能一键还原
