# 代码查询工具：安装与就绪检查

> 本体系核对规则和代码时要用两个命令行工具：`codegraph` 和 `graphify`。本页讲怎么装到「流程能跑」的程度。首次挂载时由 `GOVERNANCE_FLOW_SETUP` 调用第 6 节的就绪检查。
> 实测版本：codegraph 1.5.0、graphify 0.9.37（2026-09-25）。升级后按第 6 节重新检查一遍。

## 1. 两个工具各管什么

| 工具 | 在流程里干什么 | 用到的地方 |
|---|---|---|
| codegraph | 符号级查询：业务页的代码锚点（`function`、`Class.method`）能不能查到、在哪、谁调用它、它调用谁 | `GOVERNANCE_RULES` 的 `business-rule.md`「代码对照锚点写法」（锚点校验、链路闭合核对）；概览的 `sym` 校验；更新流程第 3 步顺锚点到代码 |
| graphify | 把代码聚成一簇簇，产出 `graphify-out/GRAPH_REPORT.md` | 概览的「两条不遗漏核对」（每簇代码都要能对上概览里的某一行）；业务初始化第 1 步圈出业务涉及的文件 |

## 2. 为什么只装命令行、不接进 AI 助手

两个工具的官方安装都分两步：第一步装命令行，第二步把工具接进 AI 助手。**本体系只做第一步。**第二步会往助手里注入这些东西：

- `codegraph install`：写入 MCP server、`CLAUDE.md` 片段、每轮提示词 hook。
- `graphify install` / `graphify claude install`：写入 skill、`CLAUDE.md` 段落，以及一个 PreToolUse hook。只要当前目录有 `graphify-out/graph.json`，每次 Grep/Read 前它都会强制要求先跑 `graphify query`，不管问的是哪类问题。

两边同时注入，会抢着决定「查代码用哪个工具」，和本体系「按场景选工具」的口径冲突。所以两个工具都只保留命令行，靠手动调用；需要成规模地调查源码时，交给专门的子代理（第 7 节）。

## 3. 安装

**codegraph**（自带运行时，不依赖本机 Node）：

```bash
curl -fsSL https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.sh | sh
# 已经有 Node 的，也可以：npm i -g @colbymchenry/codegraph
```

新开一个终端，`codegraph --version` 有输出，安装就到此为止。官方 README 的下一步 `codegraph install` 跳过。

**graphify**（PyPI 包名是双 y 的 `graphifyy`，命令名是 `graphify`）：

```bash
uv tool install graphifyy      # 或：pipx install graphifyy
```

`graphify --version` 有输出，安装就到此为止。官方 README 的下一步 `graphify install` 跳过。

**误跑了第二步怎么撤回**：

- codegraph：`codegraph uninstall` 把它从助手里摘掉。先看 `codegraph uninstall --help`：新版带 `--keep-cli` 参数，要加上，否则会连命令行本身一起卸掉；1.5.0 没有这个参数，只摘助手配置。
- graphify：`graphify uninstall`（不加 `--purge`，就会保留各项目的 `graphify-out/`）。
- `codegraph upgrade` 会自动重写已经接入过的助手配置。所以升级前确认已经摘干净，升级后再跑一遍第 6 节检查。

## 4. 在项目里建索引

在项目根目录执行：

```bash
codegraph init .      # 生成 .codegraph/
graphify update .     # 生成 graphify-out/，含 GRAPH_REPORT.md
```

- 两条都只在本地解析代码，不需要 API key，也不改全局配置。1.5.0 的 `codegraph init` 实测不装 git hooks、不留后台进程。
- `graphify update` 用每簇里连接最多的符号给簇命名（如 `load_config`），流程要的 Community Hubs、God Nodes、Communities 三段齐全。官方 README 里的 `graphify extract` 只生成 `graph.json`，还要再跑一次 `cluster-only` 才有报告，所以直接用 `update`。
- 把 `.codegraph/`、`graphify-out/` 加进 `.gitignore`。
- 项目里有符号链接、生成副本这类「同一份代码出现两次」的路径时，登记进 `DATA_PROJECT_FACTS` 的「代码索引排除路径」。查询结果按它排除，否则同一个符号会查出两条。

## 5. 日常：查询前先刷新

只用命令行时没有文件监听，改了代码索引不会跟着变。实测：新加的函数不 sync 就查不到，`codegraph status .` 会列出 `Pending Changes`。

```bash
codegraph sync .
graphify update .
```

想让提交后自动刷新，可以把下面这段加进项目的 `.git/hooks/post-commit`、`post-checkout`、`post-merge`（文件要有执行权限）。它只刷新本地索引，不碰助手配置：

```sh
#!/bin/sh
if command -v codegraph >/dev/null 2>&1; then
  ( codegraph sync >/dev/null 2>&1 & ) >/dev/null 2>&1
fi
```

graphify 对应的是 `graphify hook install`，也只装 git hooks。

## 6. 就绪检查

逐条执行，全部符合才算就绪：

| 检查 | 命令 | 期望 |
|---|---|---|
| 命令行可用 | `codegraph --version`、`graphify --version` | 都输出版本号 |
| 索引已建 | `ls .codegraph graphify-out/GRAPH_REPORT.md` | 都存在 |
| 能查到符号 | `codegraph node "<项目里一个确定存在的函数名>" -p .` | 输出含 `**Location:**` |
| 没接进助手 | `claude mcp list` | 不含 codegraph |
| 没有 hook 注入 | `grep -nE "graphify\|codegraph" ~/.claude/settings.json .claude/settings*.json` | 无命中 |

**判「查不到」看输出，不看退出码**：符号不存在时 `codegraph node` 输出 `Symbol "..." not found in the codebase`，退出码仍是 0。

## 7. 可选：源码调查子代理 code-scout

本仓库带一份 `.claude/agents/code-scout.md`，复制到项目的 `.claude/agents/` 就能用。「这个符号在哪、谁调用它、改动影响多大、这条链路怎么走、项目整体分几块」这类成规模的源码调查，交给它做：它只读不改，结论带 `file:line` 和查询范围，并按场景在 codegraph、graphify、`rg`、直接读码之间选工具。

流程本身直接调用命令行，不依赖这个子代理；它是为了让主会话不自己去翻大量代码。

## 8. 可选：让 LLM 给 graphify 的簇起名

`graphify label .` 会调用 LLM，给每簇起一个语义化的名字，流程不需要这一步。要用的话，只在这一条命令前临时设变量：

```bash
ANTHROPIC_API_KEY=... ANTHROPIC_BASE_URL=... ANTHROPIC_MODEL=... graphify label .
```

不要 `export` 到全局 shell：全局导出 `ANTHROPIC_*` 会把 Claude Code 本身也切到那个端点。其他后端的变量名见 graphify README 的环境变量表。
