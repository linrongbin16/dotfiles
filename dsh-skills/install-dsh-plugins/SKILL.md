---
name: install-dsh-plugins
description: 用于为当前 DSH profile（<profile>）安装、重装或更新插件（默认取当前 profile 已装的插件，也可用本 skill 的 plugins.json 清单指定要装哪些），并刷新它们的 pnpm minimumReleaseAgeExclude 条目；默认把这些插件从 pnpm minimumReleaseAge 中排除。也覆盖不走 registry 的两种装法：只能从 GitHub Release 下载 tgz 离线安装的插件（如 dsh-our-free-model），以及必须 git clone 到 profile 的 plugins/ 下先构建再用绝对路径 link: 安装的插件（如 dsh-connect-minmax），含 WSL 下让插件读到 Windows 桌面客户端凭据的处理。
metadata:
  version: "1.7"
---

# 安装或更新 DSH 插件

`dsh` 和 `dsh-tui` 不各自维护插件库：两者运行同一个 DSH profile，`dsh-tui`
只是该 profile 里的 TUI bundle。本 skill 默认面向**当前 profile**（`<profile>`），
profile 的 pnpm 配置位于
`<DSH_HOME>/profiles/<profile>/pnpm-workspace.yaml`，本机通常是
`~/.dsh/profiles/<profile>/pnpm-workspace.yaml`。装在这个 profile 里的插件对
`dsh`、`dsh-tui` 或该 profile 的其它入口都可见。

辅助脚本读取源 profile 的 `dsh.profile.bundles`（该列表缺失时回退到直接依赖），
确保每个 registry 插件都被排除在 pnpm 的 `minimumReleaseAge` 门槛之外，然后执行
`dsh plugin --profile <profile> add <pkg>@latest ...`，把这批插件安装或更新到最新的
兼容版本。目标 profile 里已有、但源 profile 没有的插件不会被改动。

也可以改用本 skill 目录下的 `plugins.json` 清单：它记录这台机器期望的插件列表，
不绑定某个固定 profile，本地路径用 `${PROFILE_DIR}` 按目标 profile 展开。
清单模式同样默认安装到当前 profile，不依赖任何 profile 的当前状态——新机器或
被改乱的 profile 按清单重装即可。

## 本地插件目录约定

所有不走 registry 的插件（`link:` 的本地 clone、`file:` 的离线 tgz）一律放在
**当前 profile 下的 `plugins/`**：`<DSH_HOME>/profiles/<profile>/plugins/`。
例如当前 profile 是 `web` 时就是 `~/.dsh/profiles/web/plugins/`。

```
<DSH_HOME>/profiles/<profile>/plugins/
├── dsh-connect-minmax/                    # link: 的源码 clone（含 lib/、node_modules/）
├── dsh-our-free-model-2.9.0.tgz           # file: 的离线包
└── dsh-our-free-model-2.8.5.tgz           # 旧版本，可保留可删
```

不要散落在 `~/plugins/`、`~/.dsh/plugins/`、`~/.dsh/` 根目录或 profile 的
`vendor/` 下。放在 profile 内部的理由：本地依赖和 profile 的 `node_modules`、
`pnpm-lock.yaml` 属于同一套安装状态，profile 就是它们的归属；`link:`/`file:`
规格会写成相对 profile 的 `plugins/...`，跟着 profile 目录整体搬移或复制仍成立。

多 profile 场景：每个 profile 各自维护自己的 `plugins/`。tgz 需要在多个 profile
使用时各放一份；不要用跨 profile 的相对路径去共享，那会让 profile 无法独立搬运。

`link:` 目标必须是已构建好的 clone（`npm install --include=dev && npm run build`，
产物在 `lib/`），`link:` 到源码目录不会自动编译。

## 插件清单（plugins.json）

本 skill 目录下的 `plugins.json` 记录这台机器期望的插件列表：

```json
{
  "plugins": [
    { "name": "@dmh2002/dsh-connect-minmax", "spec": "link:${PROFILE_DIR}/plugins/dsh-connect-minmax" },
    { "name": "@dmh2002/dsh-connect-qoder", "spec": "latest" },
    { "name": "dsh-connect-trae", "spec": "latest" },
    { "name": "dsh-connect-workbuddy", "spec": "latest" },
    { "name": "dsh-bash-native", "spec": "latest", "os": ["windows"] },
    { "name": "billion-context", "spec": "latest" },
    {
      "name": "dsh-our-free-model",
      "spec": "file:${PROFILE_DIR}/plugins/dsh-our-free-model-2.9.0.tgz"
    }
  ]
}
```

`spec` 支持以下按目标 profile 展开的占位符：

| 占位符 | 展开结果 |
|---|---|
| `${HOME}` | 用户主目录 |
| `${DSH_HOME}` | DSH 主目录（默认 `~/.dsh`） |
| `${PROFILE}` | 目标 profile 名，如 `web` |
| `${PROFILE_DIR}` | 目标 profile 目录，如 `~/.dsh/profiles/web` |

| 插件 | 说明 |
|---|---|
| `@dmh2002/dsh-connect-minmax` | **不在 npm registry 上**，只能装本机 clone（`<DSH_HOME>/profiles/<profile>/plugins/dsh-connect-minmax`，需先 `npm install --include=dev && npm run build`），因此清单里写 `link:${PROFILE_DIR}/plugins/dsh-connect-minmax`。完整流程见下面的「从 git clone 安装 @dmh2002/dsh-connect-minmax」。 |
| `@dmh2002/dsh-connect-qoder` | registry 包，凭据用 PAT，见下面的凭据表。 |
| `dsh-connect-trae` | registry 包，读 Trae 客户端的 storage.json。 |
| `dsh-connect-workbuddy` | registry 包，读 WorkBuddy 桌面端认证文件。 |
| `dsh-bash-native` | 只装在 Windows 上（`os: ["windows"]`），其它平台自动跳过。 |
| `billion-context` | 上下文压缩插件；更新它需要重启正在跑的会话。 |
| `dsh-our-free-model` | **离线安装**：registry 上的同名包停在 2.1.0，不能 `@latest`。必须先从 GitHub Release 下载 tgz 放到 profile 的 `plugins/`，再用 `file:` 规格安装。详见下面的「离线安装 dsh-our-free-model」。 |

用清单安装：

```bash
node "<skill-dir>/scripts/install-dsh-plugins.mjs" \
  --manifest "<skill-dir>/plugins.json" --apply
```

不带 `--profile` 时，目标就是**当前 profile**。脚本依次从
`DSH_PROFILE`、`DSH_PROFILE_DIR` 或父进程里的 `dsh --profile <name>` 推断；都推断
不到时会报错，此时显式传 `--profile <name>`。

## 离线安装 dsh-our-free-model

这个插件**不走 registry**：npm 上的同名包 `dsh-our-free-model` 停在 2.1.0
（2026-10-19 之后没再发布），而 GitHub Release 已经到 2.9.0。所以清单里写的是
`file:` 规格，装的是自己下载、校验过的 tgz——`@latest` 会把它降级成那个旧的
npm 包，不要用。

两步，先下载再安装：

**1. 从 GitHub Release 下载 tgz**

```bash
# 最新 release 的资产列表（tag + 每个资产的下载地址）
curl -sL https://api.github.com/repos/Ebony-Vinyl/dsh-our-free-model/releases/latest \
  | grep -E '"(tag_name|browser_download_url)"'
```

资产里 `dsh-our-free-model-<版本>.tgz` 是插件包，`SHA256SUMS` 是校验清单
（同目录还有桌面端的 `.exe` / `.dmg`，和插件无关）。下载并校验：

```bash
PROFILE=web                    # 换成当前 profile（或 DSH_PROFILE 的值）
PROFILE_DIR="${DSH_HOME:-$HOME/.dsh}/profiles/$PROFILE"
PLUGINS_DIR="$PROFILE_DIR/plugins"
VER=2.9.0                     # 换成上面 tag_name 去掉 v 的版本
BASE=https://github.com/Ebony-Vinyl/dsh-our-free-model/releases/download/v$VER

mkdir -p "$PLUGINS_DIR"
curl -fL "$BASE/dsh-our-free-model-$VER.tgz" -o "$PLUGINS_DIR/dsh-our-free-model-$VER.tgz"
curl -fL "$BASE/SHA256SUMS" -o /tmp/ofm-SHA256SUMS

# Windows 用 certutil -hashfile <file> SHA256，或 (Get-FileHash <file> -Algorithm SHA256).Hash
( cd "$PLUGINS_DIR" && sha256sum -c /tmp/ofm-SHA256SUMS --ignore-missing )
```

校验必须通过再往下走。`SHA256SUMS` 里那一行的目标名是
`dsh-our-free-model-<版本>.tgz`，所以要在 `$PLUGINS_DIR` 里比对。

**2. 用本地绝对路径安装**

```bash
dsh plugin --profile "$PROFILE" add \
  "$PLUGINS_DIR/dsh-our-free-model-$VER.tgz"
```

装完 dependencies 里是
`file:/home/<user>/.dsh/profiles/<profile>/plugins/dsh-our-free-model-2.9.0.tgz`
这种 file: 规格，`dsh.profile.bundles` 末尾自动多一行 `dsh-our-free-model`。

清单模式下这一步由脚本代劳——只要 tgz 已经放进 profile 的 `plugins/`，直接：

```bash
node "<skill-dir>/scripts/install-dsh-plugins.mjs" \
  --manifest "<skill-dir>/plugins.json" --apply
```

脚本对 `file:` 规格原样转发、绝不加入 `minimumReleaseAgeExclude`（本地依赖不经过
registry 门槛），`${PROFILE_DIR}` 替换成目标 profile 目录。**tgz 不在位时脚本会装失败**，所以先做
第 1 步。

### 升级

版本号写死在清单的 `spec` 里（`...-2.9.0.tgz`），升级是显式动作：

1. 按上面第 1 步下载新版本 tgz 到 profile 的 `plugins/`，校验；
2. 把 `plugins.json` 里 `dsh-our-free-model` 那条 `spec` 的版本号改成新版本
   （只有这一处；`SKILL.md` 里的示例值顺手一起改）；
3. 重跑清单安装（或直接 `dsh plugin add` 新 tgz 的绝对路径）。

旧的 tgz 可以删掉，不会自动清理。

### 注意

- **不要往 profile 的 `cordis.patch.yml` 加条目**。插件自带的
  `cordis.patch.yml` 已经 insert 了 `id: our-free-model`，再加一条会报
  `duplicate loader entry id: our-free-model`。装完就是一条 loader 条目。
- 装完要重启 `dsh` / `dsh-tui`，首次启动时插件会去注册模型、刷新可用性缓存。
- 手工复制发布文件时必须整包复制（含 `adapter/`、`src/`、`locale/`、
  包内的 `vendor/` 引擎资源与 `vendor/channel-pack/` 的 `pack.js`、WASM），只拷入口
  脚本会导致渠道加载失败——用官方 tgz 就没这个问题。
- 之前的 `@ebony-vinyl/dsh-our-free-model`（2.8.3，`link:` 装法）已废弃；
  如果 profile 里还留着，先 `dsh plugin --profile <profile> remove @ebony-vinyl/dsh-our-free-model`。

## 从 git clone 安装 @dmh2002/dsh-connect-minmax

`@dmh2002/dsh-connect-minmax` **不在 npm registry 上**（`npm view` 返回 E404），
安装方式就是它 README 的「安装」一节：把本仓库根目录作为「安装本地目录」传给
插件管理器，等价于 `plugin_manager` 的 `install_bundle`（`target` 传目录绝对路径），
在 CLI 里就是 `dsh plugin add "<abs path>"` 的 `link:` 形式。安装是**链接式**的：
改完代码只要重新 `pnpm build`，不用重装；但新增/替换的 JS 模块要重启宿主才生效。

### 1. clone 到 profile 的 plugins 目录

```bash
PROFILE=web
PROFILE_DIR="${DSH_HOME:-$HOME/.dsh}/profiles/$PROFILE"
PLUGINS_DIR="$PROFILE_DIR/plugins"

mkdir -p "$PLUGINS_DIR"
git clone https://github.com/dingminhua/dsh-connect-minmax \
  "$PLUGINS_DIR/dsh-connect-minmax"
cd "$PLUGINS_DIR/dsh-connect-minmax"
```

### 2. 构建（必须，`link:` 不会自动编译）

仓库**没有 `prepare` 脚本**（只有 `prepack: npm run build` 和 `build: tsdown`），
而 `link:` 安装不会触发 `prepack`，所以**必须手动构建**。`tsdown` / `typescript`
都在 `devDependencies` 里，装依赖时不能漏 dev：

```bash
pnpm install          # 或 npm install --include=dev
pnpm build            # → lib/index.js、lib/index.d.ts、lib/client.js
```

`lib/` 不存在或比 `src/` 旧时，`link:` 装上去会在宿主里报模块缺失/语法错误。
构建产物约 160 KB × 2（`lib/index.js` 162 KB + `lib/client.js` 161 KB）。
只想跳过测试快速确认能构建时，`pnpm run build` 就够；`pnpm run check` 会连
`typecheck`、`vitest` 一起跑。

### 3. 用绝对路径 link 安装

```bash
dsh plugin --profile "$PROFILE" add \
  "@dmh2002/dsh-connect-minmax@link:$PLUGINS_DIR/dsh-connect-minmax"
```

等价写法（显式 `link:`）：`"@dmh2002/dsh-connect-minmax@link:/abs/path"`。
装完 `package.json` 的 dependencies 是
`"@dmh2002/dsh-connect-minmax": "link:/abs/path/plugins/dsh-connect-minmax"`，
`dsh.profile.bundles` 末尾自动多一行 `@dmh2002/dsh-connect-minmax`。

`link:` 规格**不要**写进 `pnpm-workspace.yaml` 的 `minimumReleaseAgeExclude`——
本地依赖不经过 registry 门槛。

### 4. WSL 下找到 Windows 客户端的凭据（关键一步）

MiniMax Code（mcode）是 Windows 客户端，登录态在 **Windows 用户目录**：
`<WinHome>/.minimax/auth/prod/<cn|en>/mcode-public/{auth-state.json,auth.json}`。
WSL 里的插件默认按 `$HOME/.minimax` 找；如果没做软链接，就会显示「未登录」。

插件的解析顺序（`src/auth.ts` 的 `resolveDataDir`）：

```
显式 options.dataDir  >  env DSH_MINIMAX_DATA_DIR  >  join($HOME 或 $USERPROFILE, '.minimax')
```

所以最稳的做法是**显式钉住环境变量**，不依赖软链接：

```bash
# 追加到服务/入口的 env 文件，例如 ~/.dsh/service.d/web.env
DSH_MINIMAX_DATA_DIR=/mnt/c/Users/<WinUser>/.minimax
```

区域是由 `auth-state.json` 里的 `region` 决定的（`resolveLayout(dataDir,'auto')`
先试 `cn` 再试 `global`）。**只有 Windows 侧存在 `auth/prod/cn/` 时，就只有国内版
可用**；`auth/prod/en/` 不存在时国际版路由永远未登录，这是正常的，不是装错。

WSL 里 `~/.minimax` 若是 `→ /mnt/c/Users/<WinUser>/.minimax` 的软链接，默认值也能
命中；但 env 显式指定可以避免「服务由 systemd 启动、`$HOME` 与交互 shell 不一致」
这类问题，也更方便以后换机器。

自续期（`selfRenewal` 默认 true）要往 auth.json 写回，所以那个目录必须可写——
drvfs 下真实可写，动手前确认：

```bash
test -w /mnt/c/Users/<WinUser>/.minimax/auth/prod/cn/mcode-public && echo writable
```

Windows 侧的 broker 是命名管道 `\\.\pipe\mcode-auth-lease-<sha256(canonicalDataDir).slice(0,16)>`
（`src/lease.ts` 的 `windowsPipeName`），WSL 里按 Linux 逻辑去找的是 Unix socket
`<dataDir>/run/mcode-auth-lease-v1.sock` 和能力文件 `<dataDir>/run/mcode-auth-lease-v1.cap`
——两个都不存在，所以 `verify-upstream.mjs` 会打印
`❌ auth lease broker — ENOENT ... mcode-auth-lease-v1.cap；回退到本地文件：可用`，
紧接着 `✅ 可用 access token — 来源=本地文件`。**这是设计好的降级路径，不是故障**；
WSL 下能用的就是文件凭据 + 自续期。

### 5. 重启宿主（在 agent 内部要用分离的 restart）

systemd 服务就是当前 agent 的父进程，直接 `systemctl --user restart` 会把工具调用
打断（`Error: tool call aborted`）。用 `systemd-run` 把重启甩到独立 unit：

```bash
# <unit> 换成实际 unit（如 dsh-web.service）；<port> 换成 webserver 端口（如 3081）。
systemd-run --user --collect --unit=dsh-restart-$(date +%s) /bin/bash -c '
  sleep 2
  systemctl --user restart <unit>
  sleep 14
  curl -s http://127.0.0.1:<port>/plugins/dsh-connect-minmax/status > /tmp/minmax-status.json
'
```

不是 systemd 起的（前台 `dsh --profile web`）就正常重启那个进程；关键是**不要从
agent 自己的进程树里杀**，否则同样是 `tool call aborted`。

### 6. 验证

插件路由不带鉴权，loopback 上直接 curl 即可（前缀就是 loader 条目 id）：

```bash
# 登录态 + 区域 + 可用模型
curl -s http://127.0.0.1:3081/plugins/dsh-connect-minmax/status
# 期望：route=minimax、regionLabel=国内版、login.state=ready、source=file、
#       models 里出现 MiniMax-M3.1-Flash / MiniMax-M3 / MiniMax-M2.7(-highspeed)、
#       renewal.state=enabled

# 真实上游请求（注意字段是 route，不是 region）
curl -s -X POST http://127.0.0.1:3081/plugins/dsh-connect-minmax/model/test \
  -H 'content-type: application/json' \
  -d '{"route":"minimax","model":"MiniMax-M3.1-Flash"}'
# 期望：{"ok":true,"latencyMs":...,"sample":"..."}
```

`POST /model/test` 传 `{"model":...,"region":"cn"}` 会返回 400
`{"error":"route and model are required"}`——字段名是 `route`。

确认环境变量真的进了服务进程：

```bash
tr '\0' '\n' < /proc/$(systemctl --user show -p MainPID --value dsh-web.service)/environ \
  | grep DSH_MINIMAX_DATA_DIR
```

插件自带的诊断脚本（在 clone 里跑，比 curl 更细）：

```bash
DSH_MINIMAX_DATA_DIR=/mnt/c/Users/<WinUser>/.minimax node scripts/verify-upstream.mjs
```

### 7. 两个已知坑

- **`route "minimax" 已被其它 provider 注册`**：`dsh-our-free-model` 的
  `vendor/channel-pack/pack.js` 也注册了 `minimax` 产品（`registerAdapterIdempotent`
  会静默跳过并打印 `[llm-register] adapter for "minimax" 已注册…`）。两个插件都想
  占 `minimax` 这条路由时只有先注册的赢，后注册的会被 `registerRoute` 跳过
  （日志：`路由 "X" 已被其它 provider 注册…跳过`）。真要用 minmax 卡片，就先确认
  模型选择器里那条 `MiniMax（本机登录）` 是哪个插件提供的。
- **`scripts/e2e-plugin.mjs` 报 `TypeError: ctx.effect is not a function`**：那是仓库里
  过时的 stub 脚本，`apply()` 签名换了它没跟上，**不是插件缺陷**。用
  `verify-upstream.mjs` / `e2e-actions.mjs` 验证，或者直接看宿主里的卡片。

### 8. 更新

```bash
cd "$PROFILE_DIR/plugins/dsh-connect-minmax"
git pull && pnpm install && pnpm build
# 然后按第 5 步重启宿主（新 JS 模块必须重启才加载）
```

不需要重新 `dsh plugin add`：`link:` 指向同一目录，构建产物就地更新。

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

典型的 DSH profile 里有四个 connector 插件。其中三个读取桌面客户端已在本机
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
  dsh plugin --profile <profile> exec dsh-connect-workbuddy doctor
# 预期看到 "Desktop auth file: present"、"Encrypted-credential support: available"，
# 且 CN 账号数非 0。

# Qoder：PAT 已配置且上游可达。
dsh plugin --profile <profile> exec dsh-connect-qoder doctor
dsh plugin --profile <profile> exec dsh-connect-qoder status
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
# 只出计划：列出插件、当前 profile、排除块改动和将执行的命令。
node "<skill-dir>/scripts/install-dsh-plugins.mjs"

# 按清单安装到当前 profile（不绑定固定 profile）。
node "<skill-dir>/scripts/install-dsh-plugins.mjs" \
  --manifest "<skill-dir>/plugins.json" --apply

# 从当前 profile 已装的插件同步到另一个 profile。
node "<skill-dir>/scripts/install-dsh-plugins.mjs" --apply \
  --profile web

# 显式指定目标 profile（无法从当前会话推断时使用）。
node "<skill-dir>/scripts/install-dsh-plugins.mjs" \
  --manifest "<skill-dir>/plugins.json" --profile web --apply
```

选项：

| 选项 | 含义 |
|---|---|
| `--source <name>` | 读取插件列表的源 profile。默认：当前 profile。 |
| `--manifest <file>` | 读取插件列表的清单文件（JSON），而不是 profile；不带 `--profile` 时安装到当前 profile。 |
| `--profile <name>` | 目标 profile；可重复或逗号分隔。默认：当前 profile。 |
| `--apply` | 执行修改并运行 `dsh plugin add`。不加时只打印计划。 |
| `--no-age-exclude` | 不改 `minimumReleaseAgeExclude`；本次安装仍传 `--config.minimumReleaseAge=0`。 |
| `--help` | 用法。 |

当前 profile 的推断顺序：`DSH_PROFILE` → `DSH_PROFILE_DIR` 的目录名 →
父进程链中的 `dsh --profile <name>`。最后一种用于 DSH 未把 profile 名注入插件
shell 的情况；推断不到时必须用 `--profile` 显式指定。

## 脚本做了什么

清单模式（`--manifest`）：

1. 读清单 JSON，目标 profile 默认取当前 profile（显式 `--profile` 优先）。
2. 逐条处理 `plugins`：带 `os` 的条目只在列出的平台上安装（当前平台按
   `windows`/`darwin`/`linux` 判定）；按目标 profile 展开 `spec` 里的
   `${HOME}`、`${DSH_HOME}`、`${PROFILE}`、`${PROFILE_DIR}`，
   `link:`/`file:` 规格里的反斜杠转成正斜杠（pnpm 的路径解析不认反斜杠）。
3. 其余步骤与 profile 模式相同。
4. `file:` 条目在安装前先检查 tgz 在不在本地：不在就打印缺失的绝对路径并以
   退出码 1 中止（比 pnpm 埋在日志里的报错好读）。相对路径按目标 profile 解析。

profile 模式（默认）：

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
dsh plugin --profile <profile> ls
sed -n '/^minimumReleaseAgeExclude:/,/^[^ #-]/p' \
  "${DSH_HOME:-$HOME/.dsh}/profiles/<profile>/pnpm-workspace.yaml"
```

然后重启当前入口，例如 `dsh --profile <profile>` 或 `dsh-tui`。`dsh-tui doctor`
报告启动器/profile 对齐；`dsh-tui safe` 列出第三方插件。

## 排障

- `ERR_PNPM_MINIMUM_RELEASE_AGE_VIOLATION`：去掉 `--no-age-exclude` 重跑脚本；
  确认该包在目标 profile 的 `minimumReleaseAgeExclude` 中以裸包名出现。
- `ERR_PNPM_IGNORED_BUILDS`：pnpm 拦截了某个依赖的安装脚本。把该包加入目标
  `pnpm-workspace.yaml` 的 `allowBuilds`（需用户批准），然后重跑。
- 某个包在安装前兼容性检查中失败并中止整批：临时从源列表移除该包后，用
  `--profile <target>` 重跑，或用 `dsh plugin` 逐个安装其余插件。
- 更新后 `link:` 插件丢失：链接路径移动了。用
  `dsh plugin --profile <target> add <name>@link:<path>` 手动恢复。
- `link:` 插件装上了但宿主里报模块缺失 / 卡片不出：clone 没构建，或在构建前就
  `dsh plugin add` 了。进 clone 跑 `pnpm install && pnpm build`，确认 `lib/index.js`
  存在，再重启宿主。
- 插件装了但「未登录」、且只有国际版路由：数据目录解析错了。按
  「从 git clone 安装 @dmh2002/dsh-connect-minmax」第 4 步钉住
  `DSH_MINIMAX_DATA_DIR`（或对应的 `<PLUGIN>_DATA_DIR`），重启后用
  `/proc/<MainPID>/environ` 确认变量真的在服务进程里。
- 在 agent 自己启动的会话里重启服务会把工具调用打断（`Error: tool call aborted`）：
  改用 `systemd-run --user --collect` 把 `systemctl --user restart` 甩到独立 unit，
  见同一节第 5 步。
- 脚本报 `missing local package for dsh-our-free-model`：profile 的 `plugins/` 里没有
  清单指定的那个版本的 tgz。先按「离线安装 dsh-our-free-model」第 1 步下载校验，
  别改成 `latest`——那会装到 npm 上停在 2.1.0 的旧包。

