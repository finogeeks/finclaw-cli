# 安全：策略、预设、身份与能力

**English:** [security-and-policies.md](security-and-policies.md)

本文说明如何配置智能体的**允许范围**：操作系统命令执行（exec）、出站 HTTP 白名单、按工具的调用策略、LLM 默认值、**人设**（identity）以及**能力**（capability，对应不同 agent 循环/模式）。与 `finclaw policy …`、`finclaw profile apply` 配合使用。

**子命令以本机 `finclaw policy --help`、`finclaw identity --help`、`finclaw capability --help` 为准。**

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

- [profiles.zh.md](profiles.zh.md) — `profile apply`、备份与导入
- [configuration.zh.md](configuration.zh.md) — 配置与环境变量
- [finclaw-contract](https://github.com/Geeksfino/finclaw-contract) — 公开线路合同
