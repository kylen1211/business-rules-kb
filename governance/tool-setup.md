# 代码查询工具：说明与日常使用

> 本体系核对规则和代码时要用两个命令行工具：`codegraph` 和 `graphify`。装命令行、建索引、就绪检查属于准备阶段，见 `GOVERNANCE_PREPARE`；本页讲为什么不接进助手、日常怎么用。
> 实测版本：codegraph 1.5.0、graphify 0.9.37（2026-09-25）。

## 1. 两个工具各管什么

| 工具 | 在流程里干什么 | 用到的地方 |
|---|---|---|
| codegraph | 符号级查询：业务页的代码锚点（`function`、`Class.method`）能不能查到、在哪、谁调用它、它调用谁 | `GOVERNANCE_RULES` 的 `business-rule.md`「代码对照锚点写法」（锚点校验、链路闭合核对）；概览的 `sym` 校验；更新流程第 3 步顺锚点到代码 |
| graphify | 把代码聚成一簇簇，产出 `graphify-out/GRAPH_REPORT.md` | 概览的「两条不遗漏核对」（每簇代码都要能对上概览里的某一行）；业务初始化第 1 步圈出业务涉及的文件 |

## 2. 为什么只装命令行、不接进 AI 助手

两个工具的官方安装都分两步：第一步装命令行，第二步把工具接进 AI 助手。**本体系只做第一步。**

第二步会往 Claude Code 里注入下表这些东西（在隔离 HOME 里实装后逐个文件核对）。它们都在告诉 AI「查代码先用我」：codegraph 的要求先查符号，graphify 的要求先查图，而且不分问的是哪类问题。两边同时注入就会互相冲突，也和本体系「按场景选工具」的口径冲突。这套配置实际用过，也遇到了这个问题；后来把注入全部拆掉，两个工具只保留命令行、手动调用，需要成规模调查源码时交给专门的子代理（第 4 节）。

| 注入项 | 由谁写入 | 写在哪 | 注入了什么 | 谁来拆 |
|---|---|---|---|---|
| codegraph MCP server | `codegraph install` | `~/.claude.json`；项目 `.mcp.json` | MCP 工具 + 初始化时下发的使用说明，要求会话优先用它查代码 | `codegraph uninstall` |
| codegraph 提示词 hook | `codegraph install` | `settings.json` 的 UserPromptSubmit | 每轮对话往上下文里塞 codegraph 数据 | `codegraph uninstall` |
| codegraph 权限 | `codegraph install` | `settings.json` | 自动放行 `mcp__codegraph__*` | `codegraph uninstall` |
| codegraph 说明段 | `codegraph install` | `~/.claude/CLAUDE.md`；项目 `.claude/CLAUDE.md` | 带 `CODEGRAPH_START` 标记的一段，要求先用 codegraph 再 grep | `codegraph uninstall` |
| graphify skill | `graphify install` | `~/.claude/skills/graphify/` | skill 本体 | `graphify uninstall` |
| graphify skill 登记段 | `graphify install` | `~/.claude/CLAUDE.md` | `# graphify` 三行登记 | **手动删**（`graphify uninstall` 不删，0.9.37 实测） |
| graphify 读前 hook | `graphify claude install` | 项目 `.claude/settings.json` 的 PreToolUse | 目录里有 `graphify-out/graph.json` 时，每次 Grep/Read/Glob 前都强制要求先跑 `graphify query` | `graphify uninstall` |
| graphify 说明段 | `graphify claude install` | 项目 `CLAUDE.md` | 一段 graphify 说明 | `graphify uninstall` |
| graphify 旧配置备份 | `graphify claude install` | 项目 `.claude/settings.json.graphify-bak` | 写 hook 前的 settings 副本，可能带着 codegraph 的 hook 和权限 | **手动删** |
| 提交后刷新索引 | `graphify hook install`、旧版 `codegraph init` | `.git/hooks/`、`.gitattributes` | 只跑 `codegraph sync`、`graphify update`，不进 AI 上下文 | 保留（可选，见第 3 节）；`graphify uninstall` 会顺带删掉，要的话拆完重装 |

以前接入过要清理的，按 `GOVERNANCE_PREPARE`「附：以前接入过助手，或扫描有输出」。

升级：`codegraph upgrade` 会自动跑 `codegraph install --refresh`，官方说明是「Rewrite what previous installs configured, for already-configured agents only (never adds new ones)」——只装命令行时没有已接入的助手，不会写。升级后跑一次 `GOVERNANCE_TOOL_SCAN` 确认即可。graphify 升级后要重跑 `graphify hook install`（官方：hook 脚本里写死了解释器路径）。

## 3. 查询前先刷新

codegraph 的自动同步是 MCP 服务在监听文件（官方 README「How It Works」第 4 条），只用命令行时没有监听，改了代码索引不会跟着变；官方也写明在助手会话之外用索引时要先手动 sync。实测：新加的函数不 sync 就查不到，`codegraph status .` 会列出 `Pending Changes`。

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

## 4. 可选：源码调查子代理 code-scout

本仓库带一份 `.claude/agents/code-scout.md`，复制到项目的 `.claude/agents/` 就能用。「这个符号在哪、谁调用它、改动影响多大、这条链路怎么走、项目整体分几块」这类成规模的源码调查，交给它做：它只读不改，结论带 `file:line` 和查询范围，并按场景在 codegraph、graphify、`rg`、直接读码之间选工具。

流程本身直接调用命令行，不依赖这个子代理；它是为了让主会话不自己去翻大量代码。

## 5. 可选：让 LLM 给 graphify 的簇起名

`graphify label .` 会调用 LLM，给每簇起一个语义化的名字，流程不需要这一步。要用的话，只在这一条命令前临时设变量：

```bash
ANTHROPIC_API_KEY=... ANTHROPIC_BASE_URL=... ANTHROPIC_MODEL=... graphify label .
```

不要 `export` 到全局 shell：全局导出 `ANTHROPIC_*` 会把 Claude Code 本身也切到那个端点。其他后端的变量名见 graphify README 的环境变量表。
