# 配置说明

**English:** [configuration.md](configuration.md)

## 数据根目录与 profile

| 路径 | 作用 |
| --- | --- |
| `~/.finclaw` 或 `$FINCLAW_HOME` | 用户数据根目录（默认） |
| `~/.finclaw/profiles/<name>/` | 每个 profile 的隔离目录（配置、技能、策略、数据等） |
| `--profile <name>` 或 `FINCLAW_PROFILE` | 选择使用的 profile（默认可为 `default`） |

在不大范围传 `--profile` 的情况下切换“当前” profile：

```bash
finclaw profile use <name>
```

会在 finclaw 主目录下记录当前选择（例如 `active-profile` 文件）。

## 全局参数：宿主沙箱（`--security`）

`--security <isolated|restricted|yolo>` 为**全局**参数（与子命令的相对位置可按 `--help` 习惯书写，作用于**整个进程**）。**不会**写入 `config.yaml`；在运行时启动前设置与本地工具/exec 隔离相关的 `AI_INFRA_RS_*` 环境变量。它与 `policies/` 下 YAML 策略是不同层面，详见 [security-and-policies.zh.md](security-and-policies.zh.md#宿主执行沙箱security)。

## 宿主配置文件

与 LLM 提供商、密钥、守护进程开关等相关的主配置一般为 **活动 profile** 下的 YAML：

```bash
finclaw config path
```

使用 `finclaw config set`、`finclaw config show`、`finclaw config check` 查看与修改。键名以你安装的版本下 `finclaw config --help` 为准。

## 环境变量（大模型相关）

下表为常见对应关系；具体以发版与 `config check` 为准：

| 变量 | 通常对应 |
| --- | --- |
| `FINCLAW_LLM_PROVIDER` 或 `LLM_PROVIDER` | `llm.provider` |
| `FINCLAW_LLM_MODEL` 或 `LLM_MODEL` | `llm.model` |
| `FINCLAW_LLM_BASE_URL` 或 `LLM_BASE_URL` | `llm.base_url` |
| `FINCLAW_LLM_API_KEY` | `llm.api_key` |
| `OPENAI_API_KEY`、`ANTHROPIC_API_KEY`、`DEEPSEEK_API_KEY`、`LLM_API_KEY` 等 | 在未设置 finclaw 专用 key 时可能作为 `llm.api_key` 来源 |

**优先级（从高到低）：** 进程环境 → `.env`（见下） → `config.yaml` → 内置默认。

## `.env` 加载（分层）

常见顺序为：

1. **当前工作目录**下的 `./.env`（仅当你在该目录中启动 `finclaw` 时）
2. **Profile 根目录**的 `<profile_root>/.env`
3. **Finclaw 主目录**的 `~/.finclaw/.env`（或 `$FINCLAW_HOME/.env`）

若希望**无论在哪个项目目录**运行都能加载 API 密钥，请使用 `~/.finclaw/.env` 或 profile 下 `.env`，不要仅依赖某 git 仓库内的 `./.env`。

## 校验

```bash
finclaw config check
finclaw doctor
```

## 与 Claw 的 HTTP/API（依部署而定）

协议与集成细节以你所部署的 Claw 运行时及厂商/运维文档为准。子命令与参数以本机 `finclaw --help` 为准。
