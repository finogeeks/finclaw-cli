# 开发命令钩子

**English:** [hooks-develop.md](hooks-develop.md)

**用户（安装官方配方）：** [hooks.zh.md](hooks.zh.md)

本页给编写钩子命令的人。参数以本机 `finclaw hooks --help` 为准。

两种交付方式：

1. **手写 `hooks.json`**，放在当前配置档或工作区。FinClaw 发现后，你信任
   即可运行，不需要目录。
2. **官方风格配方**（与 [`hooks/recipes/`](../hooks/recipes/) 相同）：
   TypeScript 源码、组装后的 JS、`recipe.json`。接收方从目录 URL 安装，
   或你把目录拷进配置档并自行合并 `hooks.json`。

配方 **id** 不要用 TypeSafe、Jev 或其他判断产品命名。官方三件套仍会把
这些产品写成已配置的后端（见 [hooks.zh.md](hooks.zh.md#typesafe--jev)）。

## 手写 `hooks.json`

来源（均可选；配置档处理程序先运行）：

- 配置档：`<profile_root>/hooks.json`
- 项目：`<workspace>/.finclaw/hooks.json`

```json
{
  "description": "local policy",
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "exec|start_exec_job",
        "hooks": [
          {
            "type": "command",
            "command": "node /Users/you/.finclaw/hooks/guard.js",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

然后：

```bash
finclaw hooks list
finclaw hooks trust --all
```

### 命令对象

| 字段 | 含义 |
| --- | --- |
| `type` | 仅 `command` |
| `command` | Shell 命令。Unix：`$SHELL -lc`（回退 `/bin/sh`）。Windows：`cmd.exe /C` |
| `timeout` | 秒。默认 30，最小 1 |
| `async` | 不等待。在 `PreToolUse`、`PermissionRequest`、`UserPromptSubmit`、`SessionStart` 上会被拒绝 |
| `statusMessage` | 运行时可选提示 |
| `id` | 可选稳定 id（`[a-z0-9]+(?:-[a-z0-9]+)*`，最长 64）。配方必须设置 |
| `failurePolicy` | 仅 **PreToolUse** 可为 `deny`。写在其他事件上会在发现阶段报错 |
| `recipe` | 仅由 `finclaw hooks install` 写入。手写后 `hooks remove <id>` 会按该配方处理 |

`matcher` 是针对**完整**匹配串的可选正则（Codex 形状）。工具事件的匹配串是
FinClaw 工具名（`exec`、`write_file`、MCP 名等）。省略或 `*` 匹配每一次
调用。所有匹配组都会跑，不是“第一组命中即停”。

未知字段或错误正则：跳过该处理程序，会话仍可启动。

### 事件

| 事件 | 是否派发 | 处理程序能做什么 |
| --- | --- | --- |
| `PreToolUse` | 是 | 拒绝、询问（审批）、改写 `updatedInput` |
| `PermissionRequest` | 是 | 在宿主本将询问人类时允许或拒绝 |
| `PostToolUse` | 是 | 追加上下文；block 替换工具结果 |
| `UserPromptSubmit` | 是 | 拦截、改写提示词，或 `updatedModel`（同一提供商） |
| `SessionStart` | 是 | 第一次推理的 `additionalContext` |
| `SessionEnd` | 是 | 仅通知（失败开放；允许 `async`） |
| `SubagentStart` / `SubagentStop` | 是 | 通知 |
| `Stop` | 是（CLI ≥ 0.13.1） | 仅 `decision: "reject"` |
| `PreCompact`、`PostCompact`、`Interrupt` | 计入哈希与列表，**不**派发 | — |

同一事件的处理程序**按顺序**运行（先配置档后项目）。拒绝优先。改写：最后一个
未拦截的值生效。每个处理程序看到的是**原始** stdin。

`permissionDecision: "ask"`、`updatedModel` 与 Stop `reject` 需要 CLI
**0.13.1+**。0.13.0 仍会派发这些事件，但不兑现这三项。

### 标准输入

每个事件向 stdin 写一个 JSON。公共字段：`session_id`、`turn_id`、`cwd`、
`hook_event_name`、`model`、`permission_mode`、`transcript_path`（`null`）。

工具事件另有 `tool_name`、`tool_input`、`tool_use_id`；`PostToolUse` 另有
`tool_response`。

| 事件 | 额外字段 |
| --- | --- |
| `UserPromptSubmit` | `prompt` |
| `SessionStart` | `source`：`startup` 或 `resume` |
| `SessionEnd` | `reason`：`quit`、`close`、`new` 等 |
| `SubagentStart` / `SubagentStop` | `subagent_id`、`task`、`tool_name` |

当存在这些事件的已信任处理程序时，`UserPromptSubmit`、`PreToolUse`、
`PostToolUse` 与 `Stop` 还会带有有界 `turn` 对象：

```json
{
  "turn": {
    "user_text": "…",
    "assistant_text": null,
    "tools": [
      {
        "name": "exec",
        "input_summary": "…",
        "result_summary": "…"
      }
    ]
  }
}
```

上限：`user_text` / `assistant_text` 8192 UTF-8 字节；最多 32 条 `tools`
（丢最旧的）；每条摘要 1024 字节。

工作目录是会话工作区。环境继承自父进程，但会去掉密钥名（`*_API_KEY`、
已配置的 LLM 密钥名、内部令牌、`FINSAFE_LICENSE*`）。运行器会加入
`FINCLAW_HOOK_EVENT` 与 `FINCLAW_PROFILE`。没有 `pass_env`。

`TYPESAFE_API_KEY` 会随其他 `*_API_KEY` 一起被去掉。因此官方配方读取
`FINCLAW_HOOK_JUDGE_TOKEN`，并调用 TypeSafe System One
（`https://api.typesafe.ai/v1/systemone`，模型 `jev-latest`）。若你已有
TypeSafe 或 `mcp_jev` 密钥，请复制：

```bash
export FINCLAW_HOOK_JUDGE_TOKEN="$TYPESAFE_API_KEY"
```

除非你在写另一种配方，否则不要从钩子命令启动 `mcp_jev`。没有
`pass_env` 可以把 `TYPESAFE_API_KEY` 重新放进子进程。

### 标准输出与退出码

- 退出 0、空 stdout：无决策。
- 退出 0、JSON 对象：按下列规则解析。看起来像 JSON 但解析失败视为钩子失败。
- 退出 2 且 stderr 非空：在工具 / 提示词事件上视为 **block**（与 Codex
  兼容）。**不是** Stop 拒绝。
- 其他退出码：钩子失败。

**PreToolUse 拒绝 / 询问**（`ask` 需 CLI 0.13.1+）：

```json
{
  "hookSpecificOutput": {
    "permissionDecision": "deny",
    "permissionDecisionReason": "blocked by local rule"
  }
}
```

```json
{
  "hookSpecificOutput": {
    "permissionDecision": "ask"
  }
}
```

空 stdout 对你自己写的失败关闭门来说从不等于允许——请显式输出 deny/ask，
或依赖崩溃时的 `failurePolicy: deny`。

**UserPromptSubmit 路由**（CLI 0.13.1+）：

```json
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "updatedModel": "deepseek-v4-flash"
  }
}
```

id 必须在当前提供商的允许列表中（捆绑的 `finclaw model` 目录加上当前模型）。
宿主忽略提供商 / URL / 密钥变更。若请求体已指定 `model` / `provider` /
`base_url` / `api_key`，则忽略 `updatedModel`。

**Stop 拒绝**（CLI 0.13.1+）。Codex 的 `block` / 退出 2 **不是**拒绝：

```json
{
  "hookSpecificOutput": {
    "decision": "reject",
    "reason": "unsupported by tool results"
  }
}
```

`reason` 必须非空。用户看到的是该原因，而不是助手原文。不会二次推理。
已经运行过的工具不会被撤销。

默认 PreToolUse 失败（超时、崩溃）是**失败开放**，除非该处理程序设置了
`failurePolicy: deny`。`PermissionRequest` 派发失败则拒绝。

### 信任

`$FINCLAW_HOME/hooks-trust.json` 是按机器存储的。哈希覆盖事件、matcher、
命令、timeout、`async`、已设置的 `failurePolicy`、Stop 的 `stop:v1`，以及
命令解析到文件时的脚本字节（`node`、`python3`、`bash` 等）。改脚本后状态
变为 **Modified**，直到再次信任。

Claw 每次派发前会再哈希文件。会话中途改脚本则本会话剩余时间跳过该处理程序。

超时子进程按进程树终止（Unix 进程组，Windows Job Object）。

## 官方风格配方

用于希望走 `finclaw hooks install` 目录，或与已发布三件套对齐的情况。

```text
hooks/recipes/<id>/
  recipe.json
  README.md
  src/…           # TypeScript 与测试
  routes.json     # 仅 turn-router
```

`id` 为 `[a-z0-9]+(?:-[a-z0-9]+)*`，最长 64，不能以 `.` 开头。

`recipe.json` 使用 schema `hooks.recipe.v1`。每条命令**必须**有 `id`。
命令相对配方根目录（`node scripts/main.js`）。不要设置 `recipe`（安装时
盖章）。示例：
[`hooks/recipes/tool-gate/recipe.json`](../hooks/recipes/tool-gate/recipe.json)。

共享辅助在 [`hooks/lib/`](../hooks/lib/)。在本仓库中：

```bash
npm ci --prefix hooks
npm test --prefix hooks
python3 scripts/hooks_assemble.py --hooks-dir hooks --out-dir assembled-recipes
python3 scripts/hooks_pack.py \
  --recipes-dir assembled-recipes \
  --out-dir dist \
  --asset-base-url "https://example.test/catalog"
```

组装把 `src/` 编译为 `scripts/main.js`，并把 `hooks/lib/` 拷到
`scripts/lib/`。打包后的归档不得含 `node_modules` 或符号链接。接收方运行
`node scripts/main.js`（`PATH` 上要有 Node）。

目录文档 schema 为 `hooks.catalog.v1`（`id`、`latest`、`min_cli`、版本
`url` + `sha256`）。若不是官方 `hook-catalog` URL，接收方在
`extra.hooks.index_url` 指向你的索引。

官方 GitHub 标签 `hook-catalog` 是**不可变**的。维护者不能覆盖上传；新的
目录标签需要同步改 `DEFAULT_INDEX_URL` / `extra.hooks.index_url`。标签
`hooks` 已退役，不得重建。

### 不安装也能试跑

从组装树：

```bash
printf '%s' '{"hook_event_name":"PreToolUse","tool_name":"exec","tool_input":{"command":"rm -rf /"},"model":"x","turn":{"user_text":"x","assistant_text":null,"tools":[]}}' \
  | node assembled-recipes/tool-gate/scripts/main.js
```

期望 stdout 为 deny JSON，退出码 0。

## 相关

- [hooks.zh.md](hooks.zh.md) — 安装官方三件套
- 各配方说明见 [`hooks/recipes/`](../hooks/recipes/)
