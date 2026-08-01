# 双 Agent A2A 示例（HTTP + 可选对端共享）

**English:** [README.md](README.md)

在本机跑 **两个** FinClaw profile——**Callee**（入站）与 **Caller**（出站）——分别体验
真实的 **HTTP A2A**，以及可选的 **对端共享**（把同一套 A2A HTTP 隧穿到本地 URL）。
默认路径使用 **mock LLM** 与 `curl` / 脚本，**不需要** API Key。

```text
Caller                         Callee
a2a-agents.yaml  ── HTTP ──►  finclaw serve + a2a-inbound.yaml
                 ── 或 ──►    share offer ← ticket → share redeem → 本地 URL
```

## 前置条件

- `PATH` 中有 `finclaw`（见 [installation.zh.md](../../docs/installation.zh.md)）
- `curl`、`python3`（3.9+）
- 对端共享脚本需要支持 `finclaw share` 的构建（见
  [docs/a2a.zh.md](../../docs/a2a.zh.md)）；若不支持会 **干净跳过**，HTTP 路径仍可用

## 快速开始（同一台机器）

在本目录执行：

```bash
bash scripts/00-prepare-homes.sh   # 两个 FINCLAW_HOME，默认在 .demo-homes/
bash scripts/01-start-callee.sh    # 入站 serve（mock LLM）
bash scripts/02-http-smoke.sh      # Agent Card + SendMessage（HTTP）
```

可选 P2P（同机用 `--relay disabled`）：

```bash
bash scripts/03-p2p-offer.sh
bash scripts/04-p2p-redeem-smoke.sh
```

可用 `TWO_AGENT_DEMO_ROOT`、`CALLEE_PORT`、`DEMO_TOKEN`、`FINCLAW_BIN` 覆盖默认值。

### 两台机器

1. Callee 侧：prepare + start serve，再
   `SHARE_RELAY=default bash scripts/03-p2p-offer.sh`，私下发送 `ticket.txt`。
2. Caller 侧：prepare 后把 ticket 写入 `.demo-homes/ticket.txt`，再
   `SHARE_RELAY=default bash scripts/04-p2p-redeem-smoke.sh`。

共享期间两端进程需保持在线。

## 人设（markdown）

| 角色 | 文件 | 作用 |
| --- | --- | --- |
| Callee | `callee/IDENTITY.md` 等 | 接收入站 A2A |
| Caller | `caller/IDENTITY.md` 等 | 委托给 peer id `callee` |

`00-prepare-homes.sh` 会把它们拷进各 profile 的 `workspace/`。

## 配置模板

| 文件 | 作用 |
| --- | --- |
| `callee/a2a-inbound.yaml` | 入站启用 + Caller 的 bearer |
| `caller/a2a-agents.http.yaml` | 出站指向本机 HTTP |
| `caller/a2a-agents.p2p.yaml.tmpl` | redeem 后填入 `local_a2a_base` |

## 附录：真实 LLM + `/ask`

HTTP（或 P2P）就绪后：

```bash
LLM_PROVIDER=openai LLM_API_KEY=… LLM_MODEL=gpt-4o-mini \
  bash scripts/05-chat-ask-optional.sh
```

走隧道时设 `USE_P2P_AGENTS=1`。未配置真实模型时脚本会 `SKIP`。

## 清理

```bash
for n in serve-callee share-offer share-redeem; do
  f=.demo-homes/pids/$n.pid
  [[ -f $f ]] && kill "$(cat "$f")" 2>/dev/null || true
done
rm -rf .demo-homes
```

## 另见

- [docs/a2a.zh.md](../../docs/a2a.zh.md) — A2A 与对端共享指南
- `examples/mock-a2a-peer.py` — 仅出站的 mock 对端（无需第二个 finclaw）
