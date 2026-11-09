# 贡献指南

感谢你有兴趣改进 DSH-POJIA。本文件说明提交什么、怎么提交、以及必须遵守的约定。

## 一、参与前提

1. 阅读并遵守 [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)（贡献者公约 2.1）。
2. 阅读 [CONTRIBUTING-LICENSE.md](CONTRIBUTING-LICENSE.md)：本仓库有**双路径授权**，你要明确选一条。
3. 本仓库面向**本地模型与自建中转的鲁棒性评估**。请勿提交针对第三方线上服务的攻击载荷、真实凭据、真人隐私数据。

## 二、可以提交什么

| 类型 | 例子 | 要求 |
|---|---|---|
| 新模型族骨架 | `skill/references/models/<family>.md` | 必须写该族的**易踩点**（≥3 条），不能只贴一份 prompt |
| 判据用例 | `skill/scripts/suite.jsonl` 追加行 | `must_regex` / `must_not_regex` 必须是可判定的正则，且说明为什么这条能测出破甲失效 |
| 体检规则 | `pojia_probe.py` 的 `BANNED_LITERAL` / `WEAK_PATTERNS` | 附一条说明：它对应诊断表里的哪个现象 |
| 载体适配 | 新的 `--carrier` 预算档 | 给出实测字节区间与依据 |
| 文档修正 | 错字、失效链接、过时结论 | 直接提 |

## 三、不能提交什么

- 从别处**逐字复制**的 prompt 全文。若要引用上游思路，自己重写并在 `SOURCES.md` 补一行来源。
- 任何真实 token、API key、Cookie、私钥、`.env`、真实域名证书。
- 针对具体线上目标的攻击步骤、目标 IP、真实凭据。
- 违反上游许可证的内容（见 `SOURCES.md` 的「再分发限制」）。

## 四、提交前自检

```bash
# 1. 结构体检（七层完整性 / 禁用词 / 元话语 / 体积）
python skill/scripts/pojia_probe.py --check <你改的文件> --carrier <对应载体>

# 2. 脚本语法
python -m py_compile skill/scripts/pojia_probe.py skill/scripts/pojia_regress.py skill/scripts/mock_endpoint.py

# 3. 判据仍能区分（对本地假端点，不联网）
python skill/scripts/mock_endpoint.py --port 18080 --mode refusing &
python skill/scripts/pojia_regress.py \
  --base-url http://127.0.0.1:18080/v1 --model mock \
  --prompt skill/references/example-max.md \
  --suite skill/scripts/suite.jsonl --carrier proxy-light
# 期望：通过率 0%，且失败归类里出现「禁用命中」
```

四项里任一项不过，PR 不会合。

## 五、提交格式

分支：`feat/<简述>`、`fix/<简述>`、`docs/<简述>`

提交信息用约定式前缀，中文正文即可：

```
feat(models): 补 Kimi K3 族骨架与三条易踩点
fix(probe): L2 标记漏掉「冲突怎么裁决」写法
docs(sources): 补 jailbreaks 的引用范围说明
```

一个 PR 只做一件事。改 prompt 正文时，**同时**附上 `pojia_probe --check` 的前后输出。

## 六、评审标准

维护者按下面顺序看：

1. **能不能复现**——有没有给出命令与输出
2. **是不是逐字抄的**——引用上游要重写并标注
3. **层完整性**——改正文有没有破坏 L0–L6
4. **体积**——有没有超出对应载体的预算
5. **诚实度**——区分「已实测通过」与「结构上应该有效」

## 七、署名

贡献者会出现在 `CONTRIBUTORS.md`。若你不同意把自己的名字列进去，在 PR 里说明即可。
