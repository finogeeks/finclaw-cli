# 排错

**English:** [troubleshooting.md](troubleshooting.md)

## 安装与下载

- **找不到命令** — 确认安装目录（如 `$HOME/.local/bin`）在 `PATH` 中，见 [installation.zh.md](installation.zh.md)。
- **校验失败** — 重新下载 `SHA256SUMS` 与当前平台包；仅校验**你下载文件**那一行，不要对整份多平台 `SHA256SUMS` 直接 `-c`。
- **解压失败** — 安装 `zstd` 与较新 `tar`；Linux 上可试 `tar --zstd`。

**安装问题仍无法解决？** 到 [finclaw-cli issues](https://github.com/finogeeks/finclaw-cli/issues) 提交 **发版 tag、文件名、操作系统与 CPU 架构**。

## 首次运行与配置

- **`doctor` 报配置问题** — 执行 `finclaw config check`，检查 `config path`，并核对环境变量与 `.env` 的加载顺序，见 [configuration.zh.md](configuration.zh.md)。
- **只有 mock 模型** — 通过 `finclaw config set` 或环境变量配置真实 `provider` / `model` / 密钥或兼容 `base_url`。

## 策略漂移

`doctor` 若提示磁盘策略与**运行中**实例不一致：

- 重试 `finclaw policy apply` 或按 kind 应用
- 或对照 `finclaw policy show <kind> --source live` 修改本地文件

## 人设不生效

若直接编辑了 `IDENTITY.md` 而非 `finclaw identity edit`：

- 执行 `finclaw identity render`，再 `finclaw profile apply`

## 技能与启动

- **技能 id 冲突** — `finclaw skills check` 会提示；删除或重命名重复包
- **技能未加载** — 确认路径在**当前 profile** 的 `skills/<id>/SKILL.md`，并检查 `--profile`

## macOS Gatekeeper

未签名二进制被拦截时，在 **系统设置 → 隐私与安全性** 放行，或按组织策略使用签名版本。

## 能力与构建

若提示某 **capability**（如 `coding`）未启用，可能是**当前构建未包含**对应循环 — 可改用 `finclaw capability set general` 或换用包含该能力的构建。

## 导入 / 备份

- **`import --profile-only` 被拒绝** — 归档来自**全量** `backup` 而非 `backup --profile-only`；应选用正确导入方式或重新导出

## 卸载

```bash
finclaw uninstall --help
```

**务必先阅读帮助**，再确认会删除哪些数据。

## 获取帮助

- **安装/下载/校验** — [finclaw-cli issues](https://github.com/finogeeks/finclaw-cli/issues)
- **私有部署中的智能体行为** — 以所在组织支持渠道为准

## 另见

- [security-and-policies.zh.md](security-and-policies.zh.md)
- [skills.zh.md](skills.zh.md)
