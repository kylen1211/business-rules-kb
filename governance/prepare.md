# 准备阶段：装命令行、建索引

> 走任何流程（含 `GOVERNANCE_FLOW_SETUP`）之前做一次。本阶段不属于流程，不产出 kb 数据，只让本机和项目具备查代码的条件。
> 两个工具各管什么、为什么不接进 AI 助手、改代码后怎么刷新，见 `GOVERNANCE_TOOL_SETUP`。
> 依据：两个工具的官方安装说明（codegraph README「Get Started」、graphify 0.9.37 PyPI 说明「Install」）都分两步，第 1 步装命令行，第 2 步把工具接进 AI 助手。**本体系只做第 1 步。** 核实版本：codegraph 1.5.0、graphify 0.9.37（2026-09-25）。

两个工具一个一个装：装完一个，扫描确认干净，再装下一个。扫描脚本是 `GOVERNANCE_TOOL_SCAN`（挂在 `kb/` 下时是 `kb/governance/scripts/tool-residue-scan.sh`，下文写作 `<GOVERNANCE_TOOL_SCAN>`），只读不删，输出为空就是干净。

## 1. 装 codegraph 命令行

```bash
curl -fsSL https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.sh | sh
```

官方原话：「**This is the step that connects CodeGraph to your agent; installing the CLI in step 1 does not do it on its own.**」——安装脚本只把程序放进 `~/.codegraph/`，在 `~/.local/bin/` 建一个链接。官方的下一步 `codegraph install` 不跑。

新开一个终端，然后：

```bash
codegraph --version
codegraph telemetry off                              # 官方默认开启匿名使用统计，关掉
<GOVERNANCE_TOOL_SCAN> codegraph .                   # 输出为空才继续
```

## 2. 装 graphify 命令行

```bash
uv tool install graphifyy      # PyPI 包名是双 y 的 graphifyy，命令名是 graphify
```

官方第 2 步 `graphify install`（登记 skill）和「Make your assistant always use the graph」一节的 `graphify claude install`（写说明段和读前 hook）都不跑。graphify 官方说明写明没有遥测。

```bash
graphify --version
<GOVERNANCE_TOOL_SCAN> graphify .                    # 输出为空才继续
```

## 3. 在项目里建两份索引（每个项目一次）

两个工具各建一份，是两样不同的东西，都要建。在项目根目录执行：

| | codegraph 符号索引 | graphify 代码图 |
|---|---|---|
| 命令 | `codegraph init .` | `graphify update .` |
| 生成 | `.codegraph/`（主体是 SQLite 数据库 `codegraph.db`） | `graphify-out/`（`graph.json` + `GRAPH_REPORT.md`） |
| 里面是什么 | 每个函数、类、方法定义在哪个文件哪一行，以及谁调用谁 | 代码按依赖关系聚成的一簇簇，每簇有哪些节点、哪些节点连接最多 |
| 流程里谁用 | 业务页代码锚点校验、顺锚点找代码、链路闭合核对 | 概览的「不遗漏核对」、业务初始化第 1 步圈出涉及的文件 |

- 两条都只在本地解析代码，不需要 API key，也不碰助手配置（实测：建索引前后扫描结果都为空）。
- graphify 用 `update`，不用 `extract`：`extract` 只生成 `graph.json`，还要再跑一次 `cluster-only` 才有报告。`update` 用每簇里连接最多的符号给簇命名（如 `load_config`），流程要的 Community Hubs、God Nodes、Communities 三段齐全。
- 把 `.codegraph/`、`graphify-out/` 加进 `.gitignore`。
- 项目里有符号链接、生成副本这类「同一份代码出现两次」的路径，这里先记下来，走 `GOVERNANCE_FLOW_SETUP` 时登记进 `DATA_PROJECT_FACTS` 的「代码索引排除路径」。查询结果按它排除，否则同一个符号会查出两条。

## 4. 就绪检查

在项目根目录逐条执行，全部符合才算准备完成：

| 检查 | 命令 | 期望 |
|---|---|---|
| 命令行可用 | `codegraph --version`、`graphify --version` | 都输出版本号 |
| 两份索引已建 | `ls .codegraph graphify-out/GRAPH_REPORT.md` | 都存在 |
| 能查到符号 | `codegraph node "<项目里一个确定存在的函数名>" -p .` | 输出含 `**Location:**` |
| 没接进助手 | `<GOVERNANCE_TOOL_SCAN> all .` | 输出为空（stderr 里「可选保留 git 钩子」不算） |

**判「查不到」看输出，不看退出码**：符号不存在时 `codegraph node` 输出 `Symbol "..." not found in the codebase`，退出码仍是 0。

准备完成后，改了代码只需在查询前刷新（`GOVERNANCE_TOOL_SETUP`「查询前先刷新」），不用重建索引。

## 附：以前接入过助手，或扫描有输出

只清 Claude Code 这一处。一个工具清完、扫描为空，再清下一个。

**codegraph**（官方：`codegraph uninstall` 「strips CodeGraph's MCP server config, instructions, and permissions」）：

```bash
codegraph uninstall --keep-cli -y --target claude                    # 全局；--keep-cli 必带，不带会连命令行一起卸掉
codegraph uninstall --keep-cli -y --target claude --location local   # 当前项目
<GOVERNANCE_TOOL_SCAN> codegraph .
```

实测拆完只剩「项目空壳」：安装时新建、现在只剩 `{}` 的 `.mcp.json` 等，删掉即可。

**graphify**（官方：「To remove graphify from all platforms at once: `graphify uninstall`」）：

```bash
graphify uninstall             # 不加 --purge，保留 graphify-out/
<GOVERNANCE_TOOL_SCAN> graphify .
```

实测 `graphify uninstall` 拆不到、要手动清的：

- `~/.claude/CLAUDE.md` 里 `# graphify` 开头的三行登记段，整段删掉。
- `.claude/settings.json.graphify-bak`（写 hook 前留的旧 settings 备份），删掉。
- `.claude/settings.json` 里留下的空 `"hooks": {"PreToolUse": []}`：文件是 git 跟踪的，就用 `git diff` 确认只多了这一段后 `git checkout` 还原；是新建的，就整个删掉。
- `graphify uninstall` 还会顺带删掉项目 git hooks 里的刷新钩子；要的话，清完再跑 `graphify hook install`（只装 git hooks）。
