# Getting started with finclaw

This guide is for **end users** installing from [GitHub Releases](https://github.com/finogeeks/finclaw-cli/releases). The `finclaw` binary is built from a private monorepo; this public repo is the **install and documentation surface**.

**Chinese version:** [getting-started.zh.md](getting-started.zh.md)

---

## 1. Install the binary

### One-liner (recommended)

```bash
curl -fsSL "https://raw.githubusercontent.com/finogeeks/finclaw-cli/main/install.sh?$(date +%s)" | sh
```

The `?$(date +%s)` query avoids stale CDN cache for `install.sh`. You can omit it; if the script behaves oddly, retry with the query.

Pin a version:

```bash
curl -fsSL https://raw.githubusercontent.com/finogeeks/finclaw-cli/main/install.sh | sh -s -- --version 0.1.0
```

Environment variables (see `install.sh --help`):

- `FINCLAW_VERSION` — version without or with `v` prefix
- `FINCLAW_INSTALL_DIR` — default `$HOME/.local/bin`

**After install**, ensure the install dir is on `PATH` (e.g. `$HOME/.local/bin`):

```bash
finclaw --version
```

### Manual download

1. Open [Releases](https://github.com/finogeeks/finclaw-cli), pick a tag (e.g. `v0.1.0-rc`).
2. Download **one** archive for your platform (see the table in [README.md](../README.md#manual-download-full-control)) and `SHA256SUMS`.

**Checksum note:** `SHA256SUMS` lists *all* platform archives. You only have one file on disk, so do **not** run `shasum -a 256 -c SHA256SUMS` on the full file (it will try to verify missing siblings). Instead verify the single file you downloaded, for example:

```bash
VER=0.1.0-rc
FILE="finclaw-v${VER}-aarch64-apple-darwin.tar.zst"   # adjust triple to your platform
grep -F "$FILE" SHA256SUMS | shasum -a 256 -c -
```

Or compute the hash of `FILE` and compare the hex digest to the first field on the matching line in `SHA256SUMS`.

---

## 2. First-time layout: `init`

```bash
finclaw init
```

This creates the default profile layout under your Finclaw home (usually `~/.finclaw`) and a valid `config.yaml` with the **mock** LLM provider so the CLI is safe to run before you add real API keys.

---

## 3. Point finclaw at a real LLM (optional but usual)

The embedded **mock** provider is for smoke tests. For real models you set **provider**, **model**, and **API key** (or base URL for compatible endpoints).

### Option A — `finclaw config` (writes YAML on disk)

```bash
finclaw config path                    # where config.yaml lives
finclaw config set llm.provider openai
finclaw config set llm.model gpt-4.1
finclaw config set llm.api_key sk-...  # or use env for the key (see below)
```

### Option B — environment variables

| Variable | Maps to |
| --- | --- |
| `FINCLAW_LLM_PROVIDER` or `LLM_PROVIDER` | `llm.provider` |
| `FINCLAW_LLM_MODEL` or `LLM_MODEL` | `llm.model` |
| `FINCLAW_LLM_BASE_URL` or `LLM_BASE_URL` | `llm.base_url` |
| `FINCLAW_LLM_API_KEY` | `llm.api_key` |
| `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `DEEPSEEK_API_KEY`, `LLM_API_KEY` | used as `llm.api_key` if `FINCLAW_LLM_API_KEY` is unset |

**Precedence (highest first):** shell env → dotenv from `.env` files → `config.yaml` → built-in defaults.

### Option C — `.env` files (layered)

1. **Current working directory:** `./.env` (only if your shell’s cwd is that directory when you start `finclaw`)
2. **Profile root:** `<profile_root>/.env`
3. **Finclaw home:** `~/.finclaw/.env` (or `$FINCLAW_HOME/.env`)

For keys that should load **regardless of cwd**, use `~/.finclaw/.env` or the profile’s `.env`, not only a file inside a random git clone.

### Check configuration

```bash
finclaw config show
finclaw config check
finclaw doctor
```

`doctor` and `config check` surface missing keys, bad paths, and provider issues.

**Wire contract (public):** [finclaw-contract](https://github.com/Geeksfino/finclaw-contract) describes the integration surface; day-to-day CLI flags are in `finclaw --help`.

---

## 4. Talk to the agent

**Interactive REPL** (multiline, slash commands, good for exploration):

```bash
finclaw chat
```

**One shot** (script / CI, exits after the reply):

```bash
finclaw chat -m "Hello from finclaw"
```

**Long-lived process** (when you want a daemon on the machine):

```bash
finclaw serve
```

Use `finclaw model` / `finclaw model <id>` to change the model id when your provider supports it.

---

## 5. Where things live (high level)

| Location | Role |
| --- | --- |
| `~/.finclaw` (or `FINCLAW_HOME`) | Default data root |
| `~/.finclaw/profiles/<name>/` | Per-profile config, skills, policy, etc. |
| `finclaw config path` | Active `config.yaml` for the current profile |

Use `finclaw profile --help` for copy/backup flows.

**Skills:** to configure hubs, run `finclaw skills list` / `check` / `hubs` / `install`, or drop packs into `~/.finclaw/profiles/<name>/skills/<id>/`. See the main Finclaw user guide: <https://github.com/Geeksfino/finclaw/blob/main/docs/agent/managing-skills-with-finclaw.md>.

---

## 6. Updates

New builds appear on [Releases](https://github.com/finogeeks/finclaw-cli/releases). Re-run the one-liner or download the new archive, **re-verify** checksums, and replace the binary. The `finclaw update` command documents the channel; behavior depends on your edition—read the on-screen help.

---

## 7. Problems?

- **Install / download / checksum / extract:** open an [issue](https://github.com/finogeeks/finclaw-cli/issues) with the **release tag**, **file name**, and **OS + CPU** (e.g. macOS 15, arm64).
- **Product / agent behavior** (private deployments): use your org’s support channel if applicable; this repo focuses on **shipping and installing** the public binary.

---

*For a shorter overview, see the root [README.md](../README.md).*
