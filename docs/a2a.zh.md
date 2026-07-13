# finclaw 智能体互联（A2A）

**English:** [a2a.md](a2a.md)

本文说明如何用公开发布的 **finclaw** CLI 使用 **A2A（Agent2Agent）**：配置出站对等体、探活，并在聊天中用 `/ask` / `/delegate` 引导模型。文首动手实验只需 `finclaw` 二进制与 Python 3。

线路级约定（方法名、错误码、跳数头）见公开的 [A2A 互操作说明](https://github.com/Geeksfino/finclaw-contract/blob/main/docs/a2a-interop.md)（若你可访问该仓库）；否则以 `finclaw a2a --help` 与下文示例为准。

---

## 快速上手：在本地测试 A2A（建议第一步）

仅用只读 CLI 命令与一个简易 mock 对端，即可在**无需真实 LLM** 的情况下验证出站 A2A。

### 前置条件

- 已安装 `finclaw`（见 [installation.zh.md](installation.zh.md)）
- 至少执行过一次 `finclaw init`
- Python 3.9+（仅标准库）

### 1. 启动 mock A2A 对端

在本仓库中（或下载 `examples/mock-a2a-peer.py` 后）执行：

```bash
python3 examples/mock-a2a-peer.py
```

终端会打印类似：

```text
LISTENING http://127.0.0.1:54321
```

保持该终端运行，复制 base URL（不要末尾斜杠）。

### 2. 在 profile 中配置对端

创建出站对端注册表（若目录不存在请先创建）：

```text
~/.finclaw/profiles/default/runtime_home/config/a2a-agents.yaml
```

示例（将 URL 换成你的 `LISTENING` 地址）：

```yaml
agents:
  - id: mockpeer
    url: http://127.0.0.1:54321/a2a/v1
    description: 本地 mock A2A 对端
    allow_private: true
    policy: allow
```

| 字段 | 含义 |
| --- | --- |
| `id` | 在 `finclaw a2a` 与 `/ask` 中使用的短名 |
| `url` | 对端 JSON-RPC 地址（`…/a2a/v1`） |
| `allow_private: true` | 开发环境访问 `127.0.0.1` / 回环地址时必需 |
| `policy` | `allow`（立即）、`ask`（先审批）、`deny`（拒绝） |

修改配置后请重启正在运行的 `finclaw chat` 或 `finclaw serve`，以便运行时重新加载。

### 3. 检查对端（无需 LLM）

```bash
finclaw a2a list
finclaw a2a card mockpeer
finclaw a2a probe mockpeer
```

应能看到 `mockpeer`、带 `echo` 技能的 Agent Card，以及可达性探测成功。

### 4. 在对话中委派（需要真实 LLM）

先配置模型提供商（[getting-started.zh.md](getting-started.zh.md)），然后任选其一：

**自然语言** — 在 `finclaw chat` 中例如：

```text
请通过 mockpeer A2A 智能体回显 hello-a2a，并总结其回复。
```

**显式 REPL 命令** — 向模型注入委派提示：

```text
/ask mockpeer echo hello-a2a
```

详细 REPL 输出中，委派类工具调用以 `⇄` 前缀显示（例如 `⇄ a2a_send → agent=mockpeer`）。mock 成功时回复包含哨兵字符串 `A2A-REMOTE-REPLY`。

### 5. 可选：入站（让其他智能体调用你）

若需接受**外部** A2A 调用：

1. 创建 `~/.finclaw/profiles/default/runtime_home/config/a2a-inbound.yaml`（见下文 [入站配置](#入站配置a2a-inboundyaml)）。
2. 运行 `finclaw serve`（可用 `--port` 指定端口）。
3. 调用方访问 `GET http://<host>:<port>/.well-known/agent-card.json`，并对 `POST /a2a/v1` 携带 `Authorization: Bearer <token>`。

两个 finclaw 实例可互连：实例 A 开启入站 `serve`，实例 B 在 `a2a-agents.yaml` 中登记 A 的地址。

---

## finclaw 中的 A2A 原理

A2A 是**智能体对智能体**的通信，与 CLI 内部使用的 Host↔Claw HTTP API 相互独立。finclaw 支持两个方向：

| 方向 | 配置文件 | 谁发起 |
| --- | --- | --- |
| **出站** | `a2a-agents.yaml` | 你的智能体调用**远程**对端 |
| **入站** | `a2a-inbound.yaml` | **远程**对端调用你的智能体 |

若两个文件都不存在（或入站未启用），finclaw 行为与未启用 A2A 时一致：无额外 HTTP 路由、无委派工具。

### 协议表面

- **发现：** `GET /.well-known/agent-card.json` — 公开的 Agent Card（技能、版本、RPC URL）。
- **调用：** `POST <base>/a2a/v1` — JSON-RPC 2.0（`SendMessage`、流式变体；兼容旧别名 `message/send`）。
- **鉴权：** RPC 使用每对端 Bearer；Card 获取通常可匿名。
- **环路防护：** `x-a2a-hop-count` — 默认最大深度 2；超限返回 `HOP_LIMIT_EXCEEDED`。
- **追踪：** `x-a2a-trace-id` — 跨跳审计关联。

线上的 `contextId` 对应 finclaw 的 `session_id`，用于多轮委派。

### 出站：LLM 工具

当 `a2a-agents.yaml` 中至少有一个已启用对端时，Claw 运行时注册：

| 工具 | 作用 |
| --- | --- |
| `a2a_list_agents` | 列出已配置对端及 advertised 技能 |
| `a2a_send` | 向对端发送消息并返回回复 |
| `a2a_check_task` | 轮询远程长任务（对端返回 task 时） |

这些工具包含在 **`standard`** 与 **`workspace`** 工具包中（默认 `general`、`coder` 模板）。未配置对端时**不会**注册。

CLI 命令 `finclaw a2a` 为**只读检查**（list / card / probe），本身不发送对话流量。

### 入站：`finclaw serve` 上的 HTTP 入口

当 `a2a-inbound.yaml` 中 `enabled: true` 且至少有一个带 bearer 的对端时，`finclaw serve` 暴露：

- `GET /.well-known/agent-card.json`
- `POST /a2a/v1`（需鉴权）

入站轮次以 capability `a2a_inbound`、租户 `a2a-peers`、合成用户 id `a2a:<peer-id>` 运行。远程消息内容视为**不可信输入**（与 MCP 工具输出同等对待）。

### CLI 特有能力

| 功能 | 作用 |
| --- | --- |
| `finclaw a2a list\|card\|probe` | 运维/调试：验证配置、Card、可达性 |
| `/ask <peer> <message>` | REPL 快捷方式：重新发起一轮，引导模型调用 `a2a_send` |
| 工具渲染中的 `⇄` | 区分委派与本地工具 |

---

## 与 FinSAFE Hermes 适配器的对比

finclaw 与 **FinSAFE Hermes 适配器**使用**相同的 A2A 线路协议**，并共享 Rust 核心类型（`ai_infra_rs_a2a_core`），但部署形态不同：

| 主题 | finclaw CLI | Hermes 适配器 |
| --- | --- | --- |
| **主要宿主** | 桌面/单用户 CLI（`finclaw chat`、`finclaw serve`） | FinSAFE 沙箱内 Hermes，经 broker 池调度 |
| **入站配置** | `a2a-inbound.yaml` | `a2a-inbound.toml`（语义相同，格式为 TOML） |
| **出站（`a2a_send`）** | 支持 — `a2a-agents.yaml` + LLM 工具 | 以入站为主；出站委派非其主要路径 |
| **入站身份** | 租户 `a2a-peers` 下合成 `a2a:<peer-id>` | 相同模式；路由至 broker / claw-api |
| **用户界面** | `finclaw a2a`、`/ask`、对话 | 运维配置 + HTTP；无 finclaw REPL |
| **执行环境** | 默认裸机宿主（可选 FinSAFE 包裹） | 沙箱化 Hermes 执行 |

**实际互操作：** finclaw 桌面智能体可在 `a2a-agents.yaml` 中配置 Hermes 适配器 URL 与 Bearer 进行调用；远程对端也可同样方式调用**你的** finclaw 入站地址。

finclaw REPL 保留 Hermes 风格的 `/ask`、`/delegate` 肌肉记忆，但实现走 Claw 的 `a2a_send` 工具，而非独立 Hermes 客户端。

**OpenClaw 说明：** chatkit 提供 OpenClaw **风格**的 WebSocket 兼容网关用于对话，**不是**本指南所述的 A2A JSON-RPC。finclaw A2A 与 Hermes 适配器、chatkit `a2a-gateway` 对齐，而非 OpenClaw WebSocket 对话。

---

## CLI 宿主与 chatkit-middleware 宿主

**Claw 运行时**实现 A2A 工具与（可选的）直接入站入口；**宿主**决定鉴权、租户/用户 id 以及对外 URL。

### finclaw 作为 CLI 宿主（本文重点）

| 关注点 | 位置 |
| --- | --- |
| 出站对端 | `<profile>/runtime_home/config/a2a-agents.yaml` |
| 入站对端与 Card | `<profile>/runtime_home/config/a2a-inbound.yaml` |
| 入站公网 URL | 本机 + `finclaw serve --port` + 入站配置中的 `base_url` |
| 终端用户测试 | `finclaw a2a`、`finclaw chat`、`/ask` |
| 身份 | 单用户 profile；入站使用 `a2a-peers` 租户 |

出站配置解析顺序（高到低）：

1. `AI_INFRA_RS_A2A_AGENTS_CONFIG_PATH`（显式文件）
2. `$AI_INFRA_RS_HOME/config/a2a-agents.yaml`（finclaw 默认即 `runtime_home`）

入站使用 `AI_INFRA_RS_A2A_INBOUND_CONFIG_PATH` 或 `$AI_INFRA_RS_HOME/config/a2a-inbound.yaml`。

### chatkit-middleware 作为宿主（企业版）

在 **chatkit-middleware** 中运行智能体时，**宿主层**不同：Claw 仍可在运维部署 `a2a-agents.yaml` 后执行**出站** `a2a_send`，但面向外部的**入站** A2A 通常**不会**直接挂在每个 Claw 进程上。

而是由 chatkit 运行独立的 **`a2a-gateway`** 服务（默认端口 **26108**）：

```text
外部 A2A 对端
    → GET  a2a-gateway/.well-known/agent-card.json
    → POST a2a-gateway/a2a/v1（Bearer）
        → 身份映射（静态对端列表或 JWT 校验）
        → orchestrator 入站流（/flows/inbound/execute/stream）
        → ai-infra-rs Claw 智能体循环
```

| 关注点 | chatkit-middleware |
| --- | --- |
| 入站 URL | 网关公网 URL（`A2A_GATEWAY_PUBLIC_URL`），非每用户 CLI |
| 对端白名单 | 环境变量 `A2A_GATEWAY_PEERS`（token → `userId`、`tenantId`、`allowedAgents`） |
| 对外技能 | 环境变量 `A2A_GATEWAY_SKILLS` |
| 身份 | 网关将 Bearer 映射为平台主体；调用方**不能**伪造 `X-User-ID` |
| 多租户 | 网关层按用户/租户生成 Card（非桌面单 Card） |
| finclaw CLI | 终端用户**不使用**；由运维配置网关与 Claw 服务 |

**chatkit 出站：** 在 Claw 进程可解析的路径部署 `a2a-agents.yaml`（`AI_INFRA_RS_HOME` 或 `AI_INFRA_RS_A2A_AGENTS_CONFIG_PATH`）。用户经 AG-UI / orchestrator 交互；在能力配置允许时模型可调用 `a2a_send`。

**finclaw → chatkit 示例（集成方）：**

1. 运维配置 `A2A_GATEWAY_PEERS`，将 token 绑定到服务用户/租户。
2. 在 finclaw 机器上添加对端，URL 为 `https://<gateway-host>:26108/a2a/v1`，Bearer 一致。
3. 在对话中用 `/ask <id> …` 或自然语言委派。

**chatkit → finclaw 示例：** 运行带入站配置的 `finclaw serve`；在调用方 `a2a-agents.yaml`（或另一 chatkit 栈的网关对端列表）中登记 finclaw 的 URL 与 token。

---

## 配置参考

### 出站：`a2a-agents.yaml`

```yaml
defaults:
  max_hops: 2
  allow_private_network: false
agents:
  - id: legal
    url: https://legal.example.com/a2a/v1
    description: 法务专家
    auth_token_env: LEGAL_A2A_TOKEN
    policy: allow
    allowed_skills: []
    max_calls: null
    allow_private: false
    enabled: true
```

| `policy` | 行为 |
| --- | --- |
| `allow` | 立即委派 |
| `ask` | 首次 `a2a_send` 需审批；在对话审批流中同意后重试 |
| `deny` | 始终拒绝 |

密钥优先使用 `auth_token_env`，勿将 token 写入版本库；可放在 profile `.env` 或 shell 环境变量中。

### 入站：`a2a-inbound.yaml`

```yaml
enabled: true
base_url: http://127.0.0.1:26500
tenant: a2a-peers
max_hops: 2
card:
  name: my-finclaw
  description: 本地 A2A 端点
  skills:
    - id: default
      name: General
      description: 通用助手
peers:
  - id: partner-a
    auth_token_env: A2A_INBOUND_PARTNER_A_TOKEN
    allowed_agents: [default]
    allow_default: true
```

调用方须在 `POST /a2a/v1` 上发送 `Authorization: Bearer <token>`。消息元数据中的 `skillId` / `agentId` 须在 `allowed_agents` 允许范围内。

### 环境变量覆盖

| 变量 | 用途 |
| --- | --- |
| `AI_INFRA_RS_A2A_AGENTS_CONFIG_PATH` | 显式出站配置文件 |
| `AI_INFRA_RS_A2A_INBOUND_CONFIG_PATH` | 显式入站配置文件 |
| `AI_INFRA_RS_HOME` | finclaw 自动设为 `<profile>/runtime_home` |

---

## 排错

| 现象 | 检查项 |
| --- | --- |
| `finclaw a2a list` 提示无配置 | 确认 `runtime_home/config/a2a-agents.yaml` 路径；重启 chat/serve |
| `probe` 不可达 | URL 以 `/a2a/v1` 结尾；对端已启动；本机对端需 `allow_private: true` |
| 对话中无 `a2a_send` | 已配置对端；工具包为 `standard` 或 `workspace`；模型是否实际调用工具 |
| `ask` 策略卡住 | 在对话中批准委派；第二次 infer 应带 `pre_approved` |
| 入站 401 | Bearer 与 `auth_token`/环境变量一致；对端 `enabled: true` |
| 跳数超限 | 链路过深；仅在理解环路风险后提高 `max_hops` |

```bash
finclaw doctor
finclaw tools list    # 运行时可用时 — 查找 a2a_* 工具
finclaw a2a list --json
```

---

## 延伸阅读

- [chat-and-operations.zh.md](chat-and-operations.zh.md) — REPL、`finclaw serve`、slash 命令
- [configuration.zh.md](configuration.zh.md) — profile 路径与环境变量
- [reference-commands.zh.md](reference-commands.zh.md) — `finclaw a2a` 速查
- [A2A 互操作（合约）](https://github.com/Geeksfino/finclaw-contract/blob/main/docs/a2a-interop.md)
