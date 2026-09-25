# 代码查询工具：说明与日常使用

> 本体系核对规则和代码时要用两个命令行工具：`codegraph` 和 `graphify`。装工具、建索引、就绪检查属于准备阶段，见 `GOVERNANCE_PREPARE`；本页讲为什么这么装、误装了怎么撤回、日常怎么用。
> 实测版本：codegraph 1.5.0、graphify 0.9.37（2026-09-25）。

## 1. 两个工具各管什么

| 工具 | 在流程里干什么 | 用到的地方 |
|---|---|---|
| codegraph | 符号级查询：业务页的代码锚点（`function`、`Class.method`）能不能查到、在哪、谁调用它、它调用谁 | `GOVERNANCE_RULES` 的 `business-rule.md`「代码对照锚点写法」（锚点校验、链路闭合核对）；概览的 `sym` 校验；更新流程第 3 步顺锚点到代码 |
| graphify | 把代码聚成一簇簇，产出 `graphify-out/GRAPH_REPORT.md` | 概览的「两条不遗漏核对」（每簇代码都要能对上概览里的某一行）；业务初始化第 1 步圈出业务涉及的文件 |

## 2. 为什么只装命令行、不接进 AI 助手

两个工具的官方安装都分两步：第一步装命令行，第二步把工具接进 AI 助手。**本体系只做第一步。**

第二步会往助手里注入下表这些东西。它们都在告诉 AI「查代码先用我」：codegraph 的要求先查符号，graphify 的要求先查图，而且不分问的是哪类问题。两边同时注入就会互相冲突，也和本体系「按场景选工具」的口径冲突。这套配置实际用过，也遇到了这个问题；后来把注入全部拆掉，两个工具只保留命令行、手动调用，需要成规模调查源码时交给专门的子代理（第 5 节）。

| 注入项 | 由谁写入 | 注入了什么 | 处置 |
|---|---|---|---|
| codegraph MCP server | `codegraph install` | MCP 工具 + 初始化时下发的使用说明，要求会话优先用它查代码 | 拆除 |
| codegraph 提示词 hook | `codegraph install` | UserPromptSubmit hook，每轮对话往上下文里塞 codegraph 数据 | 拆除 |
| codegraph 说明段 | `codegraph install` | 在 `CLAUDE.md` / `AGENTS.md` 写一段带标记的使用说明 | 拆除 |
| codegraph 权限 | `codegraph install` | settings 里自动放行 `mcp__codegraph__*` | 拆除 |
| graphify skill | `graphify install` | 在 `~/.claude/skills/graphify/` 放 skill | 拆除 |
| graphify 读前 hook | `graphify claude install` | PreToolUse hook：目录里有 `graphify-out/graph.json` 时，每次 Grep/Read/Glob 前都强制要求先跑 `graphify query` | 拆除 |
| graphify 说明段 | `graphify claude install` | 在 `CLAUDE.md` 写一段 graphify 说明 | 拆除 |
| 提交后刷新索引 | `graphify hook install`、旧版 `codegraph init` | 只在 `.git/hooks/` 里跑 `codegraph sync`、`graphify update`，不进 AI 上下文 | 保留（可选，见第 4 节） |

要注意会「自愈回写」的情形：`codegraph upgrade` 会重写已接入过的助手配置，重跑 `codegraph install` 的默认选项全是「是」。所以升级或误跑之后，按 `GOVERNANCE_PREPARE` 第 3 步重新检查。

## 3. 误装了怎么撤回

- codegraph：`codegraph uninstall` 把它从助手里摘掉。先看 `codegraph uninstall --help`：新版带 `--keep-cli` 参数，要加上，否则会连命令行本身一起卸掉；1.5.0 没有这个参数，只摘助手配置。
- graphify：`graphify uninstall`（不加 `--purge`，就会保留各项目的 `graphify-out/`）。

## 4. 查询前先刷新

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

## 5. 可选：源码调查子代理 code-scout

本仓库带一份 `.claude/agents/code-scout.md`，复制到项目的 `.claude/agents/` 就能用。「这个符号在哪、谁调用它、改动影响多大、这条链路怎么走、项目整体分几块」这类成规模的源码调查，交给它做：它只读不改，结论带 `file:line` 和查询范围，并按场景在 codegraph、graphify、`rg`、直接读码之间选工具。

流程本身直接调用命令行，不依赖这个子代理；它是为了让主会话不自己去翻大量代码。

## 6. 可选：让 LLM 给 graphify 的簇起名

`graphify label .` 会调用 LLM，给每簇起一个语义化的名字，流程不需要这一步。要用的话，只在这一条命令前临时设变量：

```bash
ANTHROPIC_API_KEY=... ANTHROPIC_BASE_URL=... ANTHROPIC_MODEL=... graphify label .
```

不要 `export` 到全局 shell：全局导出 `ANTHROPIC_*` 会把 Claude Code 本身也切到那个端点。其他后端的变量名见 graphify README 的环境变量表。
