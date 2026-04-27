# 安全：策略、预设、身份与能力

**English:** [security-and-policies.md](security-and-policies.md)

本文说明如何配置智能体的**允许范围**：操作系统命令执行（exec）、出站 HTTP 白名单、按工具的调用策略、LLM 默认值、**人设**（identity）以及**能力**（capability，对应不同 agent 循环/模式）。与 `finclaw policy …`、`finclaw profile apply` 配合使用。

**子命令以本机 `finclaw policy --help`、`finclaw identity --help`、`finclaw capability --help` 为准。**

## 宿主执行沙箱（`--security`）

该全局开关与 **profile 下 `policies/*.yaml` 的“策略”** 是不同层面：`--security` 决定在 Claw 启动前，**本进程**为本地 **工具/exec 隔离**（如 Tier A/B、Seatbelt、bwrap、Apple Container 等）写入哪些 `AI_INFRA_RS_*` 环境变量。它不替代 `finclaw policy` 对自动批准、HTTP 白名单、exec 白名单等内容的配置。

| 取值 | 概要 |
| --- | --- |
| `isolated` | 在**当前系统与构建**上能落地的**最强本地隔离**（例如 macOS 上在栈可用时走 Apple Container；在映射到 Linux 的环境变量中对应更偏 “cloud / fail-closed” 的 bwrap 姿态）。 |
| `restricted` | 典型**桌面**沙箱：macOS 上为 Seatbelt；Linux 为偏桌面的 bwrap 组合。 |
| `yolo` | **兼容优先**的 “legacy” 宿主执行姿态；该映射会关闭所覆盖变量中的 Tier B 等。 |

**默认与提示**

- **`finclaw chat`** 在未显式传 `--security` 时，等效为 **`yolo`**，以便本地使用习惯与 OpenClaw / Hermes 系宿主相近。可打印 **stderr 提示**，建议需要更强沙箱时使用 `--security restricted` 或 `--security isolated`。
- **其他子命令** 不会在省略 `--security` 时套用这个 chat 专用默认；以本机构建/宿主基线为准（见本机 `finclaw --help`）。

**示例**

```bash
finclaw chat --security restricted
finclaw --security isolated chat -m "你好"
```

若仍**手动**设置 `AI_INFRA_RS_*`，请避免与同一进程内 `--security` 映射相冲突。实现矩阵见上游源码 `hosts/cli/src/security.rs`（finclaw 仓库）。

## 策略类型（磁盘上的 kind）

在 `<profile_root>/policies/` 下，常见文件命名习惯如下：

| 类型 | 典型文件名 | 作用 |
| --- | --- | --- |
| tool-invocation | `tool-invocation-policy.yaml` | 各工具自动执行 / 询问 / 拒绝 |
| exec | `exec-policy.yaml` | 是否允许 exec、白名单/黑名单、沙箱、网络等 |
| http-allowlist | `http-allowlist.yaml` | 出站域名与浏览器 SSRF 相关策略 |
| llm-defaults | `llm-defaults.yaml` | 温度、max tokens、思考开关等默认 |

`profile.yaml` 里 `policies:` 下也可为各 kind 指定**显式路径**；以 `finclaw profile show --resolved` 的解析结果为准。

## 在 `profile.yaml` 中选择预设（presets）

不必手写全部 YAML 时，可在 `presets:` 中使用 **snake_case** 名称：

```yaml
presets:
  exec: local_power_user
  http: api_curated
  tool: ask_for_writes
```

**没有**单独的 `finclaw preset set` 子命令 — 需编辑 `profile.yaml`（`finclaw profile edit` 或任意编辑器）后执行 `finclaw profile apply`。

### 解析顺序（简版）

每个策略 **kind** 的大致有效来源为：

1. `profile.yaml` 中为该 kind 配置的**显式文件路径**（若存在），或
2. 若存在则加载 `<profile_root>/policies/<对应文件>.yaml`，或
3. `profile.yaml` 中 `presets` 的展开结果（在 apply 时生效），或
4. 以上皆无则 **不覆盖**（skip），沿用运行时**内置基线**。

手写的 `policies/*.yaml` 对该 kind 通常**优先于**同名预设。`finclaw policy show <kind> --resolved` 可看到展开后的内容。

## 预设目录（v1 典型，以本机 `policy show --resolved` 为准）

### Exec（`presets.exec`）

| 名称 | 概要 |
| --- | --- |
| `read_only_safe` | 基本关闭类 exec 能力，黑名单覆盖等 |
| `workspace_dev` | 开启 exec，白名单为常见开发工具（**含 `curl`、不含 `ls`** 等，以解析结果为准） |
| `local_power_user` | 更宽白名单，含 **`ls`、 `curl`**、语言工具链等；仍多要求沙箱 |
| `full_admin` | 非常宽松，**应用时常有强警告** |

### HTTP（`presets.http`）

| 名称 | 概要 |
| --- | --- |
| `lan_only` | 偏向局域网/本机类地址；浏览器 SSRF 策略偏严格 |
| `api_curated` | 常见 API/Git/厂商域名的小集合；偏严格 |
| `open_internet` | 广域出站；**应用时常有强警告** |

### 工具（`presets.tool`）

| 名称 | 概要 |
| --- | --- |
| `auto_all` | 自动化程度较高 |
| `ask_for_writes` | 写类、执行类、浏览器工具等更偏确认 |
| `deny_all` | 更偏“拒绝/收紧”的 posture（以解析 YAML 为准） |

`llm-defaults` 未必在所有版本都通过同名 `presets` 简写；缺失时可写 `policies/llm-defaults.yaml` 或使用 `finclaw policy edit llm-defaults`。

## `finclaw policy` 子命令

```bash
finclaw policy show exec --source file
finclaw policy show exec --resolved
finclaw policy show exec --source live
finclaw policy edit exec
finclaw policy apply exec
finclaw policy apply
finclaw policy diff exec
finclaw policy diff --check
finclaw policy reset exec
```

**说明：** 许多版本**没有** `finclaw policy set key=value` 这类子命令，请以 `finclaw policy --help` 为准；更稳妥的方式是 `policy edit` 后 `policy apply`。

## identity 与 capability

- **Identity** — `finclaw identity`：`show` / `edit` / `render` / `reset`。若改文件后聊天未变，可执行 `identity render` 再 `profile apply`。
- **Capability** — `finclaw capability set` / `show` / `list`；单次对话可用 `finclaw chat --capability <name> -m "..."` 而不改 `profile.yaml`。

## REPL

在 `finclaw chat` 内可用 `/policy`、`/identity`、`/capability` 等；部分构建支持 `/policy reload`。以 REPL 内 `/help` 为准。

## doctor 与漂移

```bash
finclaw doctor
finclaw doctor --fix
```

出现策略漂移时，可重新 `finclaw policy apply`，或对照 `finclaw policy show <kind> --source live` 调整磁盘文件。

## 另见

- [configuration.zh.md](configuration.zh.md) — `config.yaml`、环境变量、全局参数 `--security`
- [profiles.zh.md](profiles.zh.md) — `profile apply`、备份与导入
- [finclaw-contract](https://github.com/Geeksfino/finclaw-contract) — 公开线路合同
