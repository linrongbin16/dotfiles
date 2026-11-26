---
name: install-dsh-plugins
description: 为当前 DSH profile（<profile>）安装、重装或更新插件：判断每个包该走哪条安装路径（registry / 本地 clone / 离线包 / 固定 URL），执行安装，然后验证并重启宿主。
metadata:
  version: "2.0"
---

# 安装或更新 DSH 插件

本 skill 面向**当前 profile**（`<profile>`），profile 目录是
`<DSH_HOME>/profiles/<profile>`（默认 `~/.dsh/profiles/<profile>`）。三条不变量：

1. **只通过 `dsh plugin ...` 装**（它转发给 profile 里的 pnpm）。不要手改
   `package.json`、`pnpm-lock.yaml` 或 profile 的 `cordis.patch.yml`。
2. **不走 registry 的东西放 profile 的 `plugins/` 下**，规格写成相对 profile 的路径。
3. **装完必须重启宿主**；客户端插件还要硬刷新浏览器。装成功 ≠ 能用。

本文件只写判断方法和会变的地方的**查询方式**，不写具体版本号——版本、引擎区间、
release 地址都会变，用下面的命令现查。

## 一、先判断这个包该走哪条路

| 包的状态 | 规格形态 | 要做的额外动作 |
| --- | --- | --- |
| npm registry 上有，跟随最新兼容版 | `latest` | 无 |
| npm 上有，但版本必须钉（与宿主线耦合，或上游停更在旧包） | `pkg@x.y.z` 精确版本 | 查宿主版本 → 查插件版本约束 → 手装 |
| npm 上**没有**，只有 git 仓库 | `link:<abs path>` | clone 到 `plugins/`，判断要不要构建 |
| 上游只发 Release 资产（tgz） | `file:<abs path>`（先下载）或直接传 tgz 的 https URL | 下载 + 校验 + 锁版本号 |
| 名字和 install 命令对不上（`add X` 报 404） | —— | 这个项目不在 npm 上，去它 README 找真正的发布渠道 |

三条现查命令，把「版本」这类会变的信息交给它们：

```bash
# 1) 在不在 npm 上、最新版是什么（E404 = 不在，走 clone 或 Release）
npm view <pkg> version

# 2) 上游最新 Release 的 tag 与资产地址（不在 npm 上的包都从这里拿）
curl -sL https://api.github.com/repos/<owner>/<repo>/releases/latest \
  | grep -E '"(tag_name|browser_download_url)"'

# 3) clone 下来先看要不要构建：有没有提交 lib/、有没有 build 脚本
git ls-files lib | wc -l; node -p "Object.keys(require('./package.json').scripts || {})"
```

版本必须钉时的判断顺序（不要背表，现查）：先看插件 `package.json` 的
`engines.dsh`（有就是硬约束）；没有的话看它对 `@deepseek-ai/dsh-*` 的
`peerDependencies` 区间——宿主的 peer 检查按这些区间裁决，装错会被直接拒。
装上去仍报版本不满足，就往下试一个 minor。

## 二、本地插件目录约定

不走 registry 的一律放在**当前 profile 下的 `plugins/`**：

```
<DSH_HOME>/profiles/<profile>/plugins/
├── <name>/                        # link: 的源码 clone
└── <pkg>-<version>.tgz            # file: 的离线包
```

不要散落到 `~/plugins/`、`<DSH_HOME>/plugins/` 或 profile 的 `vendor/`：本地依赖和
profile 的 `node_modules`、`pnpm-lock.yaml` 属于同一套安装状态，`link:`/`file:`
规格也写成相对 profile 的 `plugins/...`，整个 profile 目录可整体搬走。

多 profile 各维护自己的 `plugins/`；不要用跨 profile 的相对路径共享。

## 三、插件清单

`<skill-dir>/plugins.json` 记录这台机器期望装的插件，不绑定某个 profile，本地路径用
`${PROFILE_DIR}` 按目标 profile 展开。清单里的版本号是**安装当时的快照**，升级时按
第一节的命令查新值再改——不要指望清单自己跟随上游。

| 占位符 | 展开结果 |
| --- | --- |
| `${HOME}` | 用户主目录 |
| `${DSH_HOME}` | DSH 主目录（默认 `~/.dsh`） |
| `${PROFILE}` | 目标 profile 名 |
| `${PROFILE_DIR}` | 目标 profile 目录 |

清单一览（只记「为什么它不是普通的 `latest`」，装法见第一节对应路径）：

| 插件 | 判断 |
| --- | --- |
| `@dmh2002/dsh-connect-minmax` | 不在 npm 上 → clone + `link:`，且必须构建 |
| `dsh-free-search` | registry 上的同名包落后于仓库 → clone + `link:`，无需构建 |
| `dsh-our-free-model` | npm 上的同名包停更 → 从 Release 下 tgz，用 `file:` |
| `dsh-purge-community` | 只发 Release tgz → 固定版本 URL |
| `dsh-better-sidebar` | registry 包，但版本必须跟宿主线走 |
| `dsh-session-manager` | registry 包，`engines.node` 门槛较高 |
| `@dmh2002/dsh-connect-qoder`、`dsh-connect-trae`、`dsh-connect-workbuddy` | registry 包，依赖本机桌面客户端的凭据（见第八节） |
| `dsh-bash-native` | registry 包，只装在 Windows（清单里 `os: ["windows"]`，其它平台自动跳过） |
| `billion-context` | registry 包；它占着上下文压缩槽，在用它压缩的会话里更新要重启 |

## 四、运行脚本

```bash
# 只出计划（默认 dry-run）：列出插件、目标 profile、排除块改动、将执行的命令
node "<skill-dir>/scripts/install-dsh-plugins.mjs"

# 按清单装到当前 profile
node "<skill-dir>/scripts/install-dsh-plugins.mjs" --manifest "<skill-dir>/plugins.json" --apply

# 不指定清单：把当前 profile 已装的插件同步到另一个 profile
node "<skill-dir>/scripts/install-dsh-plugins.mjs" --profile <target> --apply
```

| 选项 | 含义 |
| --- | --- |
| `--source <name>` | 读取插件列表的源 profile，默认当前 profile |
| `--manifest <file>` | 从 JSON 清单取插件列表，而不是从 profile |
| `--profile <name>` | 目标 profile，可重复或逗号分隔 |
| `--apply` | 真的执行；不加只打印计划 |
| `--no-age-exclude` | 不改 `minimumReleaseAgeExclude`，本次安装仍传 `--config.minimumReleaseAge=0` |
| `--help` | 用法 |

不带 `--profile` 时目标就是当前 profile，推断顺序：`DSH_PROFILE` →
`DSH_PROFILE_DIR` 的目录名 → 父进程链里的 `dsh --profile <name>`。推断不到就显式传。

脚本行为要点：**registry 包统一按最新兼容版装**（内部用 `@latest` 加
`--config.minimumReleaseAge=0`，让「刚发布的版本装不上」不成为变量），`link:` /
`file:` / `npm:` / URL 规格原样转发、绝不写进 `minimumReleaseAgeExclude`；
`minimumReleaseAgeExclude` 里的条目一律归一化成**裸包名**。所以**要钉死某个版本就别
走脚本**——直接 `dsh plugin add <pkg>@<version>`，或者改清单后自行手装并确认。

## 五、装完怎么验证

```bash
dsh plugin --profile <profile> ls                     # 列表里有它，link: 的显示为链接
dsh --profile <profile> --dump-config \
  | grep -A6 "id: <loader entry id>"                  # 真进了 loader，就看到完整配置行
```

判断依据，按可靠性排序：

1. **`--dump-config` 里有条目行** —— 最硬的证据。前缀是 loader 条目 id，不一定等于
   包名；上下文别只给两三行，期望的配置字段常常排得更靠后。
2. **插件自己声明为无鉴权的路由**（多是 `/plugins/<entry id>/...`）能 curl 到 JSON。
3. **浏览器里卡片/面板出现且状态正常** —— 客户端插件的唯一终审。

**401 / 403 不代表没装**：`/api/*`、`/sidebar/api/*`、`/session-manager/api/*` 一类
路由要浏览器登录 cookie，loopback 上裸 curl 拿不到。别拿它当加载失败的判据。

## 六、重启宿主（在 agent 会话里要分离执行）

服务是 systemd 起的，它就是当前 agent 的父进程：直接 `systemctl --user restart`
会把工具调用打断（`Error: tool call aborted`）。把重启甩到独立 unit：

```bash
# <unit> 换成实际 unit；<port> 换成 webserver 端口
systemd-run --user --collect --unit=dsh-restart-$(date +%s) /bin/bash -c '
  sleep 2; systemctl --user restart <unit>
  sleep 14; curl -s http://127.0.0.1:<port>/ > /dev/null; echo restart-done > /tmp/dsh-restart.done
'
```

不是 systemd 起的（前台 `dsh --profile <p> --host … --port …`）就正常重启那个进程，
**不要从 agent 自己的进程树里杀**。同端口别起第二个实例，会 `EADDRINUSE`。

`link:` 插件改代码后要重新构建并重启（新增/替换的 JS 模块不会热加载）；只改客户端
bundle 时，**硬刷新浏览器**（Ctrl/Cmd+Shift+R）即可，客户端 bundle 不会自动重载。

## 七、四条安装路径的通用步骤

### registry

```bash
dsh plugin --profile <profile> add <pkg>              # 或 <pkg>@<version> 精确钉版
dsh plugin --profile <profile> update <pkg> [<pkg>…]  # 升级
```

### `link:`（本地 clone）

```bash
PROFILE_DIR="${DSH_HOME:-$HOME/.dsh}/profiles/<profile>"
git clone <repo-url> "$PROFILE_DIR/plugins/<name>" && cd "$PROFILE_DIR/plugins/<name>"
# 只在需要构建时（第一节命令 3 判断）：没有提交 lib/、且有 build 脚本
pnpm install && pnpm build
dsh plugin --profile <profile> add "<pkg>@link:$PROFILE_DIR/plugins/<name>"
```

- `link:` 是链接式安装：改完源码只需重新 `pnpm build`，不用重装。
- `link:` **不会**触发 `prepack`/`prepare`，所以上游有没有构建脚本都得自己跑一次；
  `lib/` 缺失或比 `src/` 旧，装上去就在宿主里报模块缺失。
- 仓库已经把 `lib/` 提交进 git 的，直接装，别去找 build 命令。
- 升级：`git pull && pnpm install && pnpm build`，然后重启。

### 离线 tgz（`file:`）

上游换了发布渠道、npm 上停在旧版时用这条。两步：先下载校验，再装绝对路径。

```bash
PROFILE_DIR="${DSH_HOME:-$HOME/.dsh}/profiles/<profile>"
PLUGINS_DIR="$PROFILE_DIR/plugins"; mkdir -p "$PLUGINS_DIR"
# 用第一节命令 2 拿到 tag 和资产地址，然后下载 tgz 与校验清单
curl -fL <tgz-url> -o "$PLUGINS_DIR/<pkg>-<version>.tgz"
curl -fL <SHA256SUMS-url> -o /tmp/PKG-SHA256SUMS
( cd "$PLUGINS_DIR" && sha256sum -c /tmp/PKG-SHA256SUMS --ignore-missing )   # 必须通过
dsh plugin --profile <profile> add "$PLUGINS_DIR/<pkg>-<version>.tgz"
```

校验清单里的文件名就是 `<pkg>-<version>.tgz`，所以要在 `$PLUGINS_DIR` 里比对。
手工复制上游发布文件时必须整包复制（含 `adapter/`、`vendor/`、WASM、locale 等），
只拷入口脚本会导致加载失败——用官方 tgz 不会有这个问题。旧 tgz 不会自动清理。

### 固定 URL（Release 资产直链）

```bash
dsh plugin --profile <profile> add "https://github.com/<owner>/<repo>/releases/download/<tag>/<asset>.tgz"
```

升级就是换 URL 里的 tag 和文件名，所以**必须带版本号**，不要用
`releases/latest/download/...`（同名资产可能被替换，装上什么不可复现）。
README 里给的「插件市场 / 安装器」这两条替代路径在需要备份、迁移、回滚时才有价值，
它们最终也是调用 `dsh plugin add`。

## 八、WSL 下读 Windows 客户端的凭据

connector 类插件（minmax / trae / workbuddy 等）读的是**桌面客户端在 Windows 用户目录
下**建好的凭据文件。`dsh plugin add` 成功只代表「装上了」；凭据路径不对，卡片只会显示
「未登录」，且**不会**报安装错误。

通用判断法：

```bash
WINHOME="$(wslpath "$(cmd.exe /c echo %USERPROFILE% 2>/dev/null | tr -d '\r')")"
```

- 插件默认按 `$HOME` 找，而 WSL 的 `$HOME` 不是 Windows 用户目录 → 用插件支持的
  环境变量把根目录**显式钉住**（如 `DSH_MINIMAX_DATA_DIR`、`WORKBUDDY_AUTH_FILE`、
  `WORKBUDDY_APP_EXECUTABLE`；Qoder 则是有意只认 PAT，不读客户端文件）。
  变量名以插件 README 为准，钉完用
  `tr '\0' '\n' < /proc/$(systemctl --user show -p MainPID --value <unit>)/environ | grep <VAR>`
  确认它真的进了服务进程。
- 这些 export 要放在**真正启动 dsh 的环境**里（unit 的 EnvironmentFile、wrapper 或
  登录 shell），只放在跑安装脚本的 shell 里没用。
- **不要把 Windows 文件复制到 Linux home**：会过期；某些插件的加密字段还需要
  Windows 侧可执行文件才能解。让插件直接读实时 `/mnt/c/...` 路径。
- 客户端若用**命名管道 / IPC broker** 提供凭据，WSL 一律不可达——插件回落到读文件
  是设计好的降级路径，不是故障。回落到文件要求该目录**可写**（自续期要写回），
  动手前 `test -w <dir>` 确认。
- 只有一侧区域目录存在（如只有 `cn` 没有 `en`）时，另一侧路由永远未登录，属于正常。
- 更新前后各验证一次：文件可读 → 重启 → 发一条真实请求。文件存在只是必要条件。

## 九、已知坑

| 现象 | 判断与处理 |
| --- | --- |
| `ERR_PNPM_MINIMUM_RELEASE_AGE_VIOLATION` / 报 `minimum release age` | 目标版本发布不足门槛时长。用本 skill 脚本（会写 `minimumReleaseAgeExclude` 并传 `--config.minimumReleaseAge=0`），或等够时长 |
| `ERR_PNPM_IGNORED_BUILDS` | pnpm 拦了依赖的安装脚本：把该包加进 profile `pnpm-workspace.yaml` 的 `allowBuilds`（需用户批准）再重跑，或 `pnpm approve-builds` |
| `link:` 装上了但宿主报模块缺失 / 卡片不出 | clone 没构建，或构建前就 add 了。进 clone `pnpm install && pnpm build`，确认 `lib/` 有产物，重启 |
| `link:` 插件更新后丢失 | 链接目标被移动/删了。用 `add <pkg>@link:<path>` 手动恢复 |
| 宿主启动即崩，报 `required plugins did not activate` | profile 里混进了 `@deepseek-ai/dsh-*` 副本，静态 import 绑到了混搭版本。插件通常自带 `check-profile-host-tree` 类脚本；确认后把那些副本从 `package.json`/overrides 移除并重装 |
| 页面出现两份 UI（两个侧边栏等） | 双挂载：profile `cordis.patch.yml` 里残留旧的手动 mount 行，删掉。插件自带的 patch 行只看得到它前面的条目，所以别把聚合包插到它后面 |
| `duplicate loader entry id` / `duplicate prefix route` | 同一 entry id 被挂两次（profile patch 又手加了一条）。插件的 patch 已经 insert 过，别再手加 |
| 报 `configured web provider "X" is not registered` | 提供该 provider 的插件被停用/卸载，但 profile patch 里还留着 `- id: web` 的 provider 行。删掉那两行，或用插件自带的 restore/clean 命令 |
| 日志刷 `[plugin] patch: entry "…" not found` | 宿主换了锚点名，插件侧锚点漂移。一般无害，多数插件提供 diagnose/reanchor；不影响其它插件 |
| 插件装了、路由也在，但 curl 一直 401/403 | 那些路由要浏览器 cookie（见第五节）。用 `--dump-config` 和浏览器实际行为判断 |
| 改完/装完界面没变 | 客户端 bundle 不自动重载：硬刷新浏览器；新增服务端 JS 模块还要重启宿主 |
| 安装时整批中止在某一个包 | 临时从清单里摘掉它，其余照装，单独处理这个 |

## 十、约束

- **默认 dry-run**。只有用户明确要求安装/更新时才传 `--apply`；目标列表不明确时先
  把计划展示给用户。
- 只改 `pnpm-workspace.yaml` 里 `minimumReleaseAgeExclude` 块，保留注释和无关条目。
- 更新正在被使用的 profile 不影响已加载的进程，**重启后才生效**；依赖上下文压缩的
  会话里更新对应插件要预期重启。
- 以下属于 profile 基础设施，不按插件处理：`@deepseek-ai/dsh-base`、
  `@deepseek-ai/dsh-web-app`、`@deepseek-harness-tui/dsh-tui`、`dsh-working-activity`
  （TUI patch 会自动插入它，单独添加可能重复 bundle 行）。