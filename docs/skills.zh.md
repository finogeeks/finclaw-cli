# 技能：Hub、目录、ClawHub 与本地包

**English:** [skills.md](skills.md)

Finclaw 从**活动 profile** 以及该 profile 配置的额外扫描根目录加载技能。典型磁盘布局：

```text
~/.finclaw/profiles/<profile>/skills/<skill-id>/SKILL.md
```

**以本机 `finclaw skills --help` 及各子命令 `--help` 为准。**

## 为何需要 `skills check`

安装或移动技能包后，应校验目录与 **skill id 是否冲突**（重复 id 可能导致内嵌运行时装载失败）：

```bash
finclaw skills check
```

非 `default` profile 时加 `--profile <name>`。

## 已配置的 hub

以发布 `skills.hub.v1` 等索引的站点为 **hub**：

```bash
finclaw skills hubs list
finclaw skills hubs add <name> <url>
finclaw skills hubs remove <name>
```

## 浏览、搜索、安装（通用 hub）

在已配置 hub 后：

```bash
finclaw skills browse
finclaw skills search "关键词"
finclaw skills info <引用>
finclaw skills install <引用>
finclaw skills update
finclaw skills update <id>
finclaw skills uninstall <id>
```

只读类操作可配合 `--offline` 使用本地缓存索引（见 `--help`）。

## ClawHub 适配器（公共浏览）

在典型流程中无需额外交互登录即可浏览/安装公共技能：

```bash
finclaw skills clawhub browse
finclaw skills clawhub search "主题"
finclaw skills clawhub info <slug>
finclaw skills clawhub install <slug>
```

注册表、条数等参数见 `finclaw skills clawhub --help`。

## 列出与查看配置

```bash
finclaw skills list
finclaw skills list --json
finclaw skills config
```

## 开放生态：`npx skills` 与复制到 profile

可先用外部工具生成与 OpenClaw 兼容的目录，再**复制**到本 profile 的 `skills/`：

```bash
mkdir -p /tmp/finclaw-skills-import
cd /tmp/finclaw-skills-import
npx skills add vercel-labs/agent-skills --skill frontend-design --agent openclaw --copy -y
mkdir -p ~/.finclaw/profiles/default/skills
cp -R skills/frontend-design ~/.finclaw/profiles/default/skills/
finclaw skills check
```

将 `default` 换成你的 profile 名。

## 与 Claw 的集成（依运行时而定）

协议级集成以所部署的 Claw 为准；日常仍以上述 `finclaw skills` 命令与 `--help` 为准。

## 另见

- [configuration.zh.md](configuration.zh.md) — 环境与 `config.yaml`
- [profiles.zh.md](profiles.zh.md) — profile 与备份
