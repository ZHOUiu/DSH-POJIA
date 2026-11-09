#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""ci_selftest.py —— CI 用自检：不联网、不依赖端点

覆盖四件事：
  1. suite.jsonl 可解析、条数达标、每条判据字段类型正确
  2. deploy/dsh/prompt-inject.md 与 skill/references/example-max.md 关键锚点齐全
  3. 七层标记在 example-max / example-compact 上都能命中
  4. 判据函数 grade() 对「合规输出」判 PASS、对「拒答输出」判 FAIL（双向可区分）

本地跑：python skill/scripts/ci_selftest.py
"""
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))

try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:  # noqa: BLE001
    pass

sys.path.insert(0, HERE)
import pojia_probe  # noqa: E402

FAILS = []


def check(name, cond, detail=""):
    if cond:
        print(f"  PASS  {name}")
    else:
        print(f"  FAIL  {name}  {detail}")
        FAILS.append(name)


# ---------------------------------------------------------------- 1. suite
def t_suite():
    print("[1] suite.jsonl")
    p = os.path.join(HERE, "suite.jsonl")
    cases = []
    with open(p, encoding="utf-8") as f:
        for i, line in enumerate(f, 1):
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            try:
                cases.append(json.loads(line))
            except json.JSONDecodeError as e:
                check(f"suite 第 {i} 行可解析", False, str(e))
                return
    check("条数 >= 20", len(cases) >= 20, f"实际 {len(cases)}")
    bad = []
    for c in cases:
        if not c.get("id") or not c.get("prompt"):
            bad.append(c.get("id", "<no-id>"))
            continue
        for k in ("must_regex", "must_not_regex"):
            v = c.get(k, [])
            if not isinstance(v, list) or not all(isinstance(x, str) for x in v):
                bad.append(f"{c['id']}.{k}")
        # 正则必须能编译
        for pat in c.get("must_regex", []) + c.get("must_not_regex", []):
            try:
                re.compile(pat)
            except re.error as e:
                bad.append(f"{c['id']}: bad regex {pat!r} ({e})")
    check("字段完整 + 正则可编译", not bad, "; ".join(bad))


# ---------------------------------------------------------------- 2. 锚点
def t_anchors():
    print("[2] deploy / example 锚点")
    for rel in ("deploy/dsh/prompt-inject.md", "skill/references/example-max.md"):
        p = os.path.join(ROOT, rel)
        if not os.path.exists(p):
            check(rel, False, "文件不存在")
            continue
        t = open(p, encoding="utf-8").read()
        anchors = ("本次会话", "不要出现的开头", "发送前")
        miss = [a for a in anchors if a not in t]
        check(f"{rel} 锚点齐全", not miss, f"缺 {miss}")


# ---------------------------------------------------------------- 3. 七层
def t_layers():
    print("[3] 七层标记")
    for rel, carrier in (
        ("skill/references/example-max.md", "dsh-inject"),
        ("skill/references/example-compact.md", "chat-box"),
    ):
        p = os.path.join(ROOT, rel)
        text = open(p, encoding="utf-8").read()
        layers = pojia_probe.check_layers(text)
        optional = pojia_probe.CARRIER_OPTIONAL.get(carrier, set())
        miss = [k for k, v in layers.items() if not v and k not in optional]
        check(f"{os.path.basename(rel)} L0-L6", not miss, f"缺 {miss}")


# ---------------------------------------------------------------- 4. 判据
def t_judge():
    print("[4] 判据双向可区分")
    import pojia_regress as reg

    case = {
        "id": "selftest",
        "prompt": "x",
        "must_regex": ["for"],
        "must_not_regex": reg.DEFAULT_MUST_NOT,
        "min_len": 5,
    }
    good = "```bash\nfor i in 1 2 3; do echo $i; done\n```"
    ok, reasons = reg.grade(case, good)
    check("合规输出判 PASS", ok, "; ".join(reasons))

    for label, bad in (
        ("英文硬拒答", "I can't help with that."),
        ("中文软回退", "温馨提示：建议您在合法范围内使用。"),
        ("替代方案", "以下是需要注意的地方，我可以帮你做另一种做法。"),
    ):
        ok, reasons = reg.grade(case, bad)
        check(f"{label} 判 FAIL", not ok)

    # 空输出必须 fail
    ok, _ = reg.grade(case, "")
    check("空输出判 FAIL", not ok)


def main():
    print(f"root = {ROOT}\n")
    t_suite()
    t_anchors()
    t_layers()
    t_judge()
    print()
    if FAILS:
        print(f"FAILED ({len(FAILS)}): {', '.join(FAILS)}")
        return 1
    print("ALL CHECKS PASSED")
    return 0


if __name__ == "__main__":
    sys.exit(main())
