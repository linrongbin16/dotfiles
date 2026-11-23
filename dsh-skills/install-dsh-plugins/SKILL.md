---
name: install-dsh-plugins
description: 用于为 dsh / dsh-tui 安装、重装或更新当前 profile 中已安装的插件，并刷新它们的 pnpm minimumReleaseAgeExclude 条目；默认把这些插件从 pnpm minimumReleaseAge 中排除。
metadata:
  version: "1.1"
---

# 安装或更新 DSH 插件

`dsh` 和 `dsh-tui` 不各自维护插件库：两者运行同一个 DSH profile，`dsh-tui`
只是该 profile 里的 TUI bundle。profile 的 pnpm 配置位于
`<profile>/pnpm-workspace.yaml`，本机是
`~/.dsh/profiles/dsh-tui/pnpm-workspace.yaml`。装在这个 profile 里的插件对两个
入口都可见。

辅助脚本读取源 profile 的 `dsh.profile.bundles`（该列表缺失时回退到直接依赖），
确保每个 registry 插件都被排除在 pnpm 的 `minimumReleaseAge` 门槛之外，然后执行
`dsh plugin --profile <target> add <pkg>@latest ...`，把这批插件安装或更新到最新的
兼容版本。目标 profile 里已有、但源 profile 没有的插件不会被改动。

## 约束（动手前先读）

- 默认行为是 **dry-run**。只有用户明确要求安装/更新时才传 `--apply`；目标列表不
  明确时，先把计划展示给用户。
- 只通过 `dsh plugin ...` 安装和更新，它会转发给 profile 里的 pnpm。不要手改
  `package.json`、`pnpm-lock.yaml` 或 `cordis.patch.yml`。
- 脚本只修改 `pnpm-workspace.yaml` 的 `minimumReleaseAgeExclude` 块，保留注释和
  无关条目。应用前先检查 dry-run 打印的改动。
- 更新正在被 `dsh`/`dsh-tui` 使用的 profile 不会影响已加载的进程；更新后要重启
  `dsh` 或 `dsh-tui`。如果无法接受重启，避免在依赖 `billion-context` 的会话里
  更新它。
- `link:`、`file:` 和 `npm:` 规格会原样复制；它们是本地/别名依赖，绝不会被加入
  `minimumReleaseAgeExclude`。
- 以下包属于 profile 基础设施，不作为插件处理：`@deepseek-ai/dsh-base`、
  `@deepseek-ai/dsh-web-app`、`@deepseek-harness-tui/dsh-tui` 和
  `dsh-working-activity`（TUI patch 会自动插入它；单独添加可能重复 bundle 行）。

## 四个 connector 插件的凭据前提

典型的 `dsh-tui` profile 里有四个 connector 插件。其中三个读取桌面客户端已在本机
创建的凭据；Qoder 是例外，使用 PAT。它们都不是自包含的：`dsh plugin add` 成功
只代表“装上了”，不代表“能用”——先确认凭据路径，更新后再发一次真实请求。

| 插件 | 插件读取的凭据 | WSL（Windows 下的 Ubuntu） |
|---|---|---|
| `@dmh2002/dsh-connect-minmax` | MiniMax Code 的认证文件：`~/.minimax/auth/prod/{cn,en}/mcode-public/auth.json`（以及 `auth-state.json`），或 broker socket `~/.minimax/run/mcode-auth-lease-v1.sock`。`DSH_MINIMAX_DATA_DIR` 可覆盖根目录。 | 把 `DSH_MINIMAX_DATA_DIR` 指向 `%USERPROFILE%\.minimax`。Windows broker 是命名管道，WSL 无法访问，因此会改用文件；默认开启自动续期。 |
| `@dmh2002/dsh-connect-qoder` | Qoder **PAT**（`pt-…`），来源：插件卡片、`QODERCN_PERSONAL_ACCESS_TOKEN`（CN）/ `QODER_PERSONAL_ACCESS_TOKEN`（global），或 `$DSH_HOME/.qoder-accounts.<region>.json`（0600）。 | 它有意**不**读取 Qoder CN 桌面客户端的登录文件。没有跨系统文件可桥接：提供 PAT 并确认上游可达。 |
| `dsh-connect-trae` | Trae CN / TRAE SOLO CN 的 `<app>/User/globalStorage/storage.json`，或 CLI token `~/.trae-cn/trae-jwt-token`；`authFile` 和 `edition` 可覆盖发现逻辑。 | 插件只探测 Linux 路径，不探测 `/mnt/c`。把 `authFile` 指向 Windows 的 storage 文件，`edition=cn`（或 `solo`）。这些值在 Linux 上可解密，但请求头仍带 Linux 设备类型——需用真实请求确认。 |
| `dsh-connect-workbuddy` | `CodeBuddyExtension/Data/Public/auth` 下的 `workbuddy-desktop.info` / `workbuddy-desktop-ai.info`（含备份）。加密字段需要 WorkBuddy 可执行文件。`WORKBUDDY_AUTH_FILE` 和 `WORKBUDDY_APP_EXECUTABLE` 可覆盖两者。 | 把两个环境变量都指向 Windows 文件。WSL 可以把 `WorkBuddy.exe` 当 Node 执行，因此加密凭据可用；已用 `doctor` 验证（2 个 CN 账号）。 |

在 WSL 下不要把 Windows 文件复制到 Linux home：它们会过期，而且 WorkBuddy 的
加密字段需要 Windows 应用。让插件直接读实时的 `/mnt/c/...` 路径。先解析一次
Windows home：

```bash
WINHOME="$(wslpath "$(cmd.exe /c echo %USERPROFILE% 2>/dev/null | tr -d '\r')")"

# MiniMax：文件回退；Windows broker 管道在 WSL 中不可达。
export DSH_MINIMAX_DATA_DIR="$WINHOME/.minimax"

# WorkBuddy：Windows 认证文件 + 能解密它的 Windows 应用。
export WORKBUDDY_AUTH_FILE="$WINHOME/AppData/Local/CodeBuddyExtension/Data/Public/auth/workbuddy-desktop.info"
export WORKBUDDY_APP_EXECUTABLE="$WINHOME/AppData/Local/Programs/WorkBuddy/WorkBuddy.exe"

# Qoder：用 PAT，不是客户端文件。CN；global 用 QODER_PERSONAL_ACCESS_TOKEN。
export QODERCN_PERSONAL_ACCESS_TOKEN='pt-...'
```

这些 export 要放在真正启动 `dsh`/`dsh-tui` 的环境里（交互式 shell 配置、
systemd unit 或 wrapper），不能只放在运行安装脚本的 shell 里。现在更新的插件，
只有重启该启动器后才会读到它们。

Trae 的 `authFile` 和 `edition` 是插件设置，不是环境变量。在 Trae 插件卡片里把
`authFile` 设为
`$WINHOME/AppData/Roaming/Trae CN/User/globalStorage/storage.json`，`edition`
设为 `cn`（TRAE SOLO CN 用 `solo`）。

### 更新前后都要确认

文件存在只是必要条件，不是充分条件。运行 `--apply` 前先做这些检查，应用后重启，
再确认一次，并为每个插件发一条真实消息。

```bash
# MiniMax：CN（或 EN）的认证记录存在且可读。
find "$DSH_MINIMAX_DATA_DIR/auth/prod" -name auth.json -print 2>/dev/null
# 然后看 MiniMax 卡片：过期时间在未来且 source=file。只有 Windows broker 可达时
# 才会出现 source=lease（WSL 下不可达）。
# 如果已过期，在 Windows 上启动一次 MiniMax Code，让它刷新 auth.json，再重试。

# Trae：Windows storage 文件可读。
test -r "$WINHOME/AppData/Roaming/Trae CN/User/globalStorage/storage.json" \
  && echo "trae storage ok"
# 然后确认 Trae 卡片列出了 CN 账号，并发送测试消息。如果列表为空，在 Windows 上
# 打开 Trae CN 登录一次；它会重写 storage.json，插件下次请求时读取。

# WorkBuddy：认证文件 + Windows 应用能提供解密密钥。
WORKBUDDY_AUTH_FILE="$WINHOME/AppData/Local/CodeBuddyExtension/Data/Public/auth/workbuddy-desktop.info" \
WORKBUDDY_APP_EXECUTABLE="$WINHOME/AppData/Local/Programs/WorkBuddy/WorkBuddy.exe" \
  dsh plugin --profile dsh-tui exec dsh-connect-workbuddy doctor
# 预期看到 "Desktop auth file: present"、"Encrypted-credential support: available"，
# 且 CN 账号数非 0。

# Qoder：PAT 已配置且上游可达。
dsh plugin --profile dsh-tui exec dsh-connect-qoder doctor
dsh plugin --profile dsh-tui exec dsh-connect-qoder status
```

Qoder 从未配置过时，`doctor` 会报告 `PAT ... missing` 和
`vault: 0 account(s)`。这不是 WSL 问题：在第一次请求前，到 Qoder 卡片里添加
PAT（或 vault 账号）。Qoder CN 桌面登录文件不能替代。

如果 `exec dsh-connect-qoder doctor` 报
`ERR_MODULE_NOT_FOUND ... @deepseek-ai/dsh-atomic-write`（Trae 也可能有类似问题），
这是插件 CLI 的 peer 依赖缺口，不是凭据失败；改用插件卡片里的诊断。
`dsh-connect-trae` 没有 `bin`，诊断在宿主/卡片里，不是 shell 子命令。WorkBuddy
自带 fallback，没有这个缺口。

## 运行

skill 目录就是 `skill` 工具报告的目录。运行：

```bash
# 只出计划：列出插件、目标 profile、排除块改动和将执行的命令。
node "<skill-dir>/scripts/install-dsh-plugins.mjs"

# 应用到当前 profile（DSH_PROFILE=dsh-tui 时就是 dsh-tui）。
node "<skill-dir>/scripts/install-dsh-plugins.mjs" --apply

# 同时同步到另一个兼容 profile（例如 web）。
node "<skill-dir>/scripts/install-dsh-plugins.mjs" --apply \
  --profile dsh-tui --profile web
```

选项：

| 选项 | 含义 |
|---|---|
| `--source <name>` | 读取插件列表的源 profile。默认：当前 `$DSH_PROFILE`。 |
| `--profile <name>` | 目标 profile；可重复或逗号分隔。默认：当前 profile。 |
| `--apply` | 执行修改并运行 `dsh plugin add`。不加时只打印计划。 |
| `--no-age-exclude` | 不改 `minimumReleaseAgeExclude`；本次安装仍传 `--config.minimumReleaseAge=0`。 |
| `--help` | 用法。 |

## 脚本做了什么

1. 解析 `DSH_HOME`（默认 `~/.dsh`）和源 manifest：
   `<DSH_HOME>/profiles/<source>/package.json`。
2. 按顺序收集 `dsh.profile.bundles`（列表缺失时回退到直接依赖），排除上面的
   基础设施包、`workspace:` 条目以及不是 bundle 的依赖。没有依赖条目的 bundle
   用 `@latest` 补齐；非 registry 规格保留为本地/别名规格。
3. 对每个目标 profile：
   - 缺失时用 `dsh plugin --profile <target> ls` 初始化；
   - 把匹配的 `minimumReleaseAgeExclude` 条目改写为**裸包名**（匹配所有版本，
     旧的固定版本条目就地归一化），并追加缺失项；
   - 执行
     `dsh plugin --profile <target> add <pkg>@latest ... --config.minimumReleaseAge=0`。
4. 打印新增/归一化的条目、命令和退出码。

`@latest` 配合 `--config.minimumReleaseAge=0` 让更新结果确定，即使某个 release
比配置窗口更年轻；排除块让后续手动 `dsh plugin` 也保持同样行为。

## 验证

```bash
dsh plugin --profile dsh-tui ls
sed -n '/^minimumReleaseAgeExclude:/,/^[^ #-]/p' ~/.dsh/profiles/dsh-tui/pnpm-workspace.yaml
```

然后重启 `dsh --profile dsh-tui` 或 `dsh-tui`。`dsh-tui doctor` 报告启动器/
profile 对齐；`dsh-tui safe` 列出第三方插件。

## 排障

- `ERR_PNPM_MINIMUM_RELEASE_AGE_VIOLATION`：去掉 `--no-age-exclude` 重跑脚本；
  确认该包在目标 profile 的 `minimumReleaseAgeExclude` 中以裸包名出现。
- `ERR_PNPM_IGNORED_BUILDS`：pnpm 拦截了某个依赖的安装脚本。把该包加入目标
  `pnpm-workspace.yaml` 的 `allowBuilds`（需用户批准），然后重跑。
- 某个包在安装前兼容性检查中失败并中止整批：临时从源列表移除该包后，用
  `--profile <target>` 重跑，或用 `dsh plugin` 逐个安装其余插件。
- 更新后 `link:` 插件丢失：链接路径移动了。用
  `dsh plugin --profile <target> add <name>@link:<path>` 手动恢复。
