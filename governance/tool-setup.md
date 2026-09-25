# 代码查询工具：安装与就绪检查

> 本体系核对规则和代码时要用两个命令行工具：`codegraph` 和 `graphify`。本页讲怎么装到「流程能跑」的程度。首次挂载时由 `GOVERNANCE_FLOW_SETUP` 调用第 6 节的就绪检查。
> 实测版本：codegraph 1.5.0、graphify 0.9.37（2026-09-25）。升级后按第 6 节重新检查一遍。

## 1. 两个工具各管什么

| 工具 | 在流程里干什么 | 用到的地方 |
|---|---|---|
| codegraph | 符号级查询：业务页的代码锚点（`function`、`Class.method`）能不能查到、在哪、谁调用它、它调用谁 | `GOVERNANCE_RULES` 的 `business-rule.md`「代码对照锚点写法」（锚点校验、链路闭合核对）；概览的 `sym` 校验；更新流程第 3 步顺锚点到代码 |
| graphify | 把代码聚成一簇簇，产出 `graphify-out/GRAPH_REPORT.md` | 概览的「两条不遗漏核对」（每簇代码都要能对上概览里的某一行）；业务初始化第 1 步圈出业务涉及的文件 |

## 2. 为什么只装命令行、不接进 AI 助手

两个工具的官方安装都分两步：第一步装命令行，第二步把工具接进 AI 助手。**本体系只做第一步。**

第二步会往助手里注入下表这些东西。它们都在告诉 AI「查代码先用我」：codegraph 的要求先查符号，graphify 的要求先查图，而且不分问的是哪类问题。两边同时注入就会互相冲突，也和本体系「按场景选工具」的口径冲突。这套配置实际用过，也遇到了这个问题；后来把注入全部拆掉，两个工具只保留命令行、手动调用，需要成规模调查源码时交给专门的子代理（第 7 节）。

| 注入项 | 由谁写入 | 注入了什么 | 处置 |
|---|---|---|---|
| codegraph MCP server | `codegraph install` | MCP 工具 + 初始化时下发的使用说明，要求会话优先用它查代码 | 拆除 |
| codegraph 提示词 hook | `codegraph install` | UserPromptSubmit hook，每轮对话往上下文里塞 codegraph 数据 | 拆除 |
| codegraph 说明段 | `codegraph install` | 在 `CLAUDE.md` / `AGENTS.md` 写一段带标记的使用说明 | 拆除 |
| codegraph 权限 | `codegraph install` | settings 里自动放行 `mcp__codegraph__*` | 拆除 |
| graphify skill | `graphify install` | 在 `~/.claude/skills/graphify/` 放 skill | 拆除 |
| graphify 读前 hook | `graphify claude install` | PreToolUse hook：目录里有 `graphify-out/graph.json` 时，每次 Grep/Read/Glob 前都强制要求先跑 `graphify query` | 拆除 |
| graphify 说明段 | `graphify claude install` | 在 `CLAUDE.md` 写一段 graphify 说明 | 拆除 |
| 提交后刷新索引 | `graphify hook install`、旧版 `codegraph init` | 只在 `.git/hooks/` 里跑 `codegraph sync`、`graphify update`，不进 AI 上下文 | 保留（可选，见第 5 节） |

要注意会「自愈回写」的情形：`codegraph upgrade` 会重写已接入过的助手配置，重跑 `codegraph install` 的默认选项全是「是」。所以升级或误跑之后，按第 6 节重新检查。

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
| 没有 hook 和权限注入 | `grep -nE "graphify\|codegraph" ~/.claude/settings.json .claude/settings*.json` | 无命中 |
| 没有 skill | `ls ~/.claude/skills .claude/skills \| grep -iE "graphify\|codegraph"` | 无命中 |
| 没有说明段 | `grep -nE "graphify\|codegraph" ~/.claude/CLAUDE.md CLAUDE.md AGENTS.md` | 无命中（只查项目根目录的文件，`kb/governance/` 里的方法论文件本来就会提到这两个工具） |

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
