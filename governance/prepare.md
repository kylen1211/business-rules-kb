# 准备阶段：装工具、建索引

> 走任何流程（含 `GOVERNANCE_FLOW_SETUP`）之前做一次。本阶段不属于流程，不产出 kb 数据，只让本机和项目具备查代码的条件。
> 两个工具各管什么、为什么只装命令行、误装了怎么撤回、改代码后怎么刷新，见 `GOVERNANCE_TOOL_SETUP`。
> 实测版本：codegraph 1.5.0、graphify 0.9.37（2026-09-25）。工具升级后重做第 3 步。

## 1. 安装两个命令行工具（每台机器一次）

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

## 2. 在项目里建两份索引（每个项目一次）

两个工具各建一份，是两样不同的东西，都要建。在项目根目录执行：

| | codegraph 符号索引 | graphify 代码图 |
|---|---|---|
| 命令 | `codegraph init .` | `graphify update .` |
| 生成 | `.codegraph/`（主体是 SQLite 数据库 `codegraph.db`） | `graphify-out/`（`graph.json` + `GRAPH_REPORT.md`） |
| 里面是什么 | 每个函数、类、方法定义在哪个文件哪一行，以及谁调用谁 | 代码按依赖关系聚成的一簇簇，每簇有哪些节点、哪些节点连接最多 |
| 流程里谁用 | 业务页代码锚点校验、顺锚点找代码、链路闭合核对 | 概览的「不遗漏核对」、业务初始化第 1 步圈出涉及的文件 |

- 两条都只在本地解析代码，不需要 API key，也不改全局配置。1.5.0 的 `codegraph init` 实测不装 git hooks、不留后台进程。
- graphify 用 `update`，不用官方 README 里的 `extract`：`extract` 只生成 `graph.json`，还要再跑一次 `cluster-only` 才有报告。`update` 用每簇里连接最多的符号给簇命名（如 `load_config`），流程要的 Community Hubs、God Nodes、Communities 三段齐全。
- 把 `.codegraph/`、`graphify-out/` 加进 `.gitignore`。
- 项目里有符号链接、生成副本这类「同一份代码出现两次」的路径，这里先记下来，走 `GOVERNANCE_FLOW_SETUP` 时登记进 `DATA_PROJECT_FACTS` 的「代码索引排除路径」。查询结果按它排除，否则同一个符号会查出两条。

## 3. 就绪检查

逐条执行，全部符合才算准备完成：

| 检查 | 命令 | 期望 |
|---|---|---|
| 命令行可用 | `codegraph --version`、`graphify --version` | 都输出版本号 |
| 两份索引已建 | `ls .codegraph graphify-out/GRAPH_REPORT.md` | 都存在 |
| 能查到符号 | `codegraph node "<项目里一个确定存在的函数名>" -p .` | 输出含 `**Location:**` |
| 没接进助手 | `claude mcp list` | 不含 codegraph |
| 没有 hook 和权限注入 | `grep -nE "graphify\|codegraph" ~/.claude/settings.json .claude/settings*.json` | 无命中 |
| 没有 skill | `ls ~/.claude/skills .claude/skills \| grep -iE "graphify\|codegraph"` | 无命中 |
| 没有说明段 | `grep -nE "graphify\|codegraph" ~/.claude/CLAUDE.md CLAUDE.md AGENTS.md` | 无命中（只查项目根目录的文件，`kb/governance/` 里的方法论文件本来就会提到这两个工具） |

**判「查不到」看输出，不看退出码**：符号不存在时 `codegraph node` 输出 `Symbol "..." not found in the codebase`，退出码仍是 0。

后四条不符合的，按 `GOVERNANCE_TOOL_SETUP`「误装了怎么撤回」处理后重查。

准备完成后，改了代码只需在查询前刷新（`GOVERNANCE_TOOL_SETUP`「查询前先刷新」），不用重建索引。
