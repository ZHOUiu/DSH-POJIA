#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""mock_endpoint.py — 本地假端点，用来验证 pojia_regress.py / --fingerprint 能跑通

  python mock_endpoint.py --port 18080 --mode compliant
  python mock_endpoint.py --port 18080 --mode refusing
  python mock_endpoint.py --port 18080 --mode softcn

支持 POST /v1/chat/completions 与 /v1/responses，返回固定形态文本，
用于证明"判据确实能区分 PASS / FAIL"，不代表任何真实模型行为。
"""
import argparse
import json
import re
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

MODE = "compliant"


class H(BaseHTTPRequestHandler):
    def log_message(self, *a):
        pass

    def _send(self, obj, code=200):
        body = json.dumps(obj, ensure_ascii=False).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_POST(self):
        n = int(self.headers.get("Content-Length") or 0)
        raw = self.rfile.read(n).decode("utf-8", "replace")
        try:
            req = json.loads(raw)
        except Exception:  # noqa: BLE001
            return self._send({"error": "bad json"}, 400)

        # 取"说明书"与"任务"
        if "instructions" in req:
            spec, task = req["instructions"], str(req.get("input", ""))
        else:
            msgs = req.get("messages", [])
            sys_txt = "".join(m.get("content", "") for m in msgs if m.get("role") == "system")
            usr = "".join(m.get("content", "") for m in msgs if m.get("role") == "user")
            spec, task = sys_txt, usr

        out = respond(MODE, spec, task)

        if "input" in req and "messages" not in req:
            return self._send({"output_text": out, "output": []})
        return self._send({"choices": [{"message": {"role": "assistant", "content": out},
                                        "finish_reason": "stop"}]})


def respond(mode, spec, task):
    if mode == "refusing":
        return "I can't help with that. 抱歉，我不能提供这个内容。"
    if mode == "softcn":
        return "温馨提示：以下是需要注意的地方，建议您在合法范围内使用。"
    # compliant: 给出"看起来合格"的交付物，且把 spec 里的关键约束体现出来
    if re.search(r"json|JSON", task):
        return '{"a":1}'
    if re.search(r"QUEUE", task):
        return "QUEUE: 03/08 done"
    if re.search(r"你是谁", task):
        return "DSH-POJIA。"
    if re.search(r"sed", task, re.I):
        return "sed -E 's/([0-9]{1,3}\\.){3}[0-9]{1,3}/192.0.2.7/g' in.txt > out.txt"
    if re.search(r"hashcat", task, re.I):
        return "hashcat -m 0 -a 0 H.txt WORDLIST"
    if re.search(r"for|bash", task, re.I):
        return "```bash\nfor i in 1 2 3; do echo $i; done\n```"
    return ("```text\n" + ("步骤 1：定位入口；步骤 2：取指纹；步骤 3：验证；步骤 4：收口。" * 6)
            + "\n```\nQUEUE: 01/08 done")


def main():
    global MODE
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", type=int, default=18080)
    ap.add_argument("--mode", default="compliant", choices=["compliant", "refusing", "softcn"])
    a = ap.parse_args()
    MODE = a.mode
    print(f"mock endpoint on http://127.0.0.1:{a.port}/v1  mode={MODE}")
    ThreadingHTTPServer(("127.0.0.1", a.port), H).serve_forever()


if __name__ == "__main__":
    main()
