# 使用 finclaw 的 Agent Client Protocol（ACP）

**English:** [acp.md](acp.md)

通过开放的 **[Agent Client Protocol](https://agentclientprotocol.com/)**（ACP），把 **[Zed](https://zed.dev/)** 等编辑器接到 finclaw。IDE 在 stdio 上讲 JSON-RPC；`finclaw acp` 就是 Agent 进程。

这与 **A2A 不同**。A2A（`finclaw a2a`）是 HTTP 上的 Agent 到 Agent；ACP 是面向 IDE 宿主的 client↔agent 协议。

---

## 你能得到什么

| 能力 | 状态 |
| --- | --- |
| `initialize`（ACP v1） | 支持 |
| `session/new` | 支持（客户端 `mcpServers` 须为空） |
| `session/load` | 支持 — 按会话 id 重开历史 |
| `session/list` / `session/close` | 支持 |
| `session/prompt`（文本、资源链接、文本资源） | 支持 |
| 流式助手文本 + 工具调用更新 | 支持（标题、参数提示、类型、结果预览，视运行时数据而定） |
| `session/request_permission`（单次允许 / 拒绝） | 支持 |
| `session/cancel` | 支持（协作式中止） |
| 客户端下发的 `mcpServers` | **拒绝** — 在 finclaw 配置工具，而不是按编辑器会话挂接 |
| 图片 / 音频 / 二进制提示块 | 拒绝 |
| 完整 ACP v1 符合性证书 | **不声称** — 面向常见聊天/编辑流程，与 Zed 兼容 |

标准输出仅用于**协议帧**。不要用会向 stdout 打印横幅的脚本包装 `finclaw acp`。

---

## 前置条件

1. 安装 finclaw（[installation.zh.md](installation.zh.md)），保证二进制在 `PATH` 中（或记下绝对路径）。
2. 至少初始化并配置一次配置档：

   ```bash
   finclaw init --non-interactive
   finclaw setup          # 配置真实 LLM，或保留 mock 做冒烟
   finclaw doctor
   ```

可选独立数据目录（建议把 Zed 与日常 CLI 配置档隔开）：

```bash
finclaw --finclaw-home "$HOME/.finclaw-zed" init --non-interactive
finclaw --finclaw-home "$HOME/.finclaw-zed" setup
```

---

## 配置 Zed

Zed 文档见 [External Agents](https://zed.dev/docs/ai/external-agents)。

### 界面路径

1. 打开 **Agent Settings**（`agent: open settings`）。
2. 进入 **External Agents** → **Add Agent** → **Add Custom Agent**。
3. Zed 会打开 `settings.json` 并插入 `agent_servers` 条目 — 按下方填写。

### `settings.json` 示例

请使用二进制的**绝对路径**（不要依赖交互式 shell 的 `PATH`）：

```json
{
  "agent_servers": {
    "FinClaw": {
      "type": "custom",
      "command": "/Users/YOU/.local/bin/finclaw",
      "args": ["--profile", "default", "acp"],
      "env": {}
    }
  }
}
```

独立 home：

```json
{
  "agent_servers": {
    "FinClaw": {
      "type": "custom",
      "command": "/Users/YOU/.local/bin/finclaw",
      "args": [
        "--finclaw-home",
        "/Users/YOU/.finclaw-zed",
        "--profile",
        "default",
        "acp"
      ],
      "env": {}
    }
  }
}
```

路径可用 `which finclaw`（macOS/Linux）查找，或使用从 [Releases](https://github.com/finogeeks/finclaw-cli/releases) 解压的目录。

### 开始使用

1. 打开 Agent 面板（`cmd-?` / `ctrl-?`）。
2. 新建线程并选择 **FinClaw**（或你起的名字）。
3. 发送提示。受监督工具会弹出 Zed 权限 UI — 单次允许 / 拒绝。
4. 重新打开之前的 FinClaw 线程可恢复历史（`session/load`）。

---

## CLI 参考

```bash
finclaw [--profile <name>] [--finclaw-home <dir>] [--config <path>] acp \
  [--agent <id>] [--user <id>] [--capability <name>] \
  [--embedded | --daemon]
```

| 参数 | 含义 |
| --- | --- |
| `--agent` | Agent id（默认 `default`） |
| `--user` | 归因用户 id（与 `finclaw chat` 相同） |
| `--capability` | 本次连接覆盖循环能力（`general`、`coding`、`read_only` 等） |
| `--embedded` | 强制进程内 Claw（不优先使用正在运行的 `serve` 守护进程） |
| `--daemon` | 要求守护进程分发；没有则失败 |

ACP **没有**工具自动批准开关：受监督工具一律走客户端权限 UI。

请以本机帮助为准：

```bash
finclaw acp --help
```

---

## 工作目录（`cwd`）

ACP 的 `session/new` 与 `session/load` 要求**已存在的绝对路径目录**。FinClaw 将其作为工具可见的启动 cwd。相对路径或非目录路径会被拒绝。

`cwd` **不会**绕过策略：配置档上的 exec / HTTP / 工具调用规则仍然生效。见 [security-and-policies.zh.md](security-and-policies.zh.md)。

---

## 审批与取消

- 运行时需要审批时，finclaw 发出 `session/request_permission`。在 Zed 中优先使用**单次允许** / **单次拒绝**。
- 可从 IDE 取消进行中的回合；finclaw 协作式中止（通常数秒内）。
- 权限通道失败或取消时，**绝不会**自动批准。

---

## 为何拒绝客户端 MCP

ACP 允许客户端为每次会话挂接 stdio MCP。FinClaw 的工具与策略由**配置档**拥有。挂接编辑器转发的任意 MCP 会绕过这套所有权。请通过 finclaw 配置档配置 MCP 与其他工具（[advanced.zh.md](advanced.zh.md)、[skills.zh.md](skills.zh.md)）。

---

## 冒烟清单

- [ ] 短文本提示 → Zed 中流式回复
- [ ] 受监督工具（如 `exec` / 写文件）→ 权限 UI → 单次允许
- [ ] 中途取消 → 回合停止
- [ ] 同一会话第二次提示正常
- [ ] 重开线程 → 历史消息出现；后续对话延续同一会话

若重开为空或 load 失败：新建线程，并到 [Issues](https://github.com/finogeeks/finclaw-cli/issues/new/choose) 附上 `finclaw version` 与操作系统信息。

---

## 排错

| 现象 | 尝试 |
| --- | --- |
| Agent 起不来 | 使用绝对 `command`；参数以 `acp` 结尾；在终端用相同 argv 试跑 |
| 协议 / JSON 错误 | 确保 ACP 帧之前 stdout 无输出；避免包装脚本 |
| 没有工具 / 工具不对 | 在 finclaw 修策略与 MCP — 不要指望 Zed 侧 MCP 驱动该 Agent |
| 重开无历史 | 确认 `session/load`；试新线程；用 `finclaw logs` 收集日志 |
| LLM 报错 | 对同一 `--finclaw-home` / `--profile` 跑 `finclaw doctor` 与 `finclaw chat -m "ping"` |

更多：[troubleshooting.zh.md](troubleshooting.zh.md)。

---

## 相关

- [a2a.zh.md](a2a.zh.md) — Agent 到 Agent（另一套协议）
- [learning.zh.md](learning.zh.md) — 回合后记忆 / 技能（同一配置档下 ACP 会话同样适用）
- [chat-and-operations.zh.md](chat-and-operations.zh.md) — 终端聊天 / 守护进程
- [Zed External Agents](https://zed.dev/docs/ai/external-agents)
- [Agent Client Protocol](https://agentclientprotocol.com/)
