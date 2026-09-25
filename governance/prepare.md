# 准备阶段：装命令行、建索引

> 本阶段不属于流程，不产出 kb 数据，只让本机和项目具备查代码的条件。分两部分，夹在项目适配前后：
> **第一部分（每台机器一次）→ `GOVERNANCE_FLOW_SETUP` 项目适配（登记「代码位置」）→ 第二部分（每个项目一次）→ 各条流程。**
> 依据：两个工具官方安装说明的前两步（codegraph README「Get Started」、graphify 0.9.37 PyPI 说明「Install」），第 1 步装命令行，第 2 步把工具接进 AI 助手。**本体系只做第 1 步。** 核实版本：codegraph 1.5.0、graphify 0.9.37（2026-09-25）。
> 两个工具各管什么、为什么不接进助手、改代码后怎么刷新，见 `GOVERNANCE_TOOL_SETUP`。

**扫描脚本** `GOVERNANCE_TOOL_SCAN`，下文写作 `<扫描>`：只读不删，按注入特征查 Claude Code 的配置，输出为空就是干净。挂载前从 business-rules-kb 的克隆目录运行 `governance/scripts/tool-residue-scan.sh`；挂载到 `kb/` 后是 `kb/governance/scripts/tool-residue-scan.sh`。参数是工具名和要查的目录：查启动 Claude Code 的那个目录。

## 第一部分：装命令行（每台机器一次）

两个工具一个一个装：装完一个，扫描干净，再装下一个。

### 1. 装 codegraph

```bash
curl -fsSL https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.sh | sh
```

官方原话：「**This is the step that connects CodeGraph to your agent; installing the CLI in step 1 does not do it on its own.**」——安装脚本只把程序放进 `~/.codegraph/`，在 `~/.local/bin/` 建一个链接。官方的下一步 `codegraph install` 不跑。

新开一个终端：

```bash
codegraph --version
codegraph telemetry off          # 官方默认开启匿名使用统计，关掉
<扫描> codegraph .               # 输出为空才继续
```

### 2. 装 graphify

前提：Python 3.10+ 和 uv（官方「Prerequisites」；没有 uv 的按官方表格装）。

```bash
uv tool install graphifyy        # PyPI 包名是双 y 的 graphifyy，命令名是 graphify
```

官方第 2 步 `graphify install`（登记 skill）和「Make your assistant always use the graph」一节的 `graphify claude install`（写说明段和读前 hook）都不跑。graphify 官方说明写明没有遥测。

```bash
graphify --version
<扫描> graphify .                # 输出为空才继续
```

## 第二部分：建索引（每个项目一次，项目适配之后）

`DATA_PROJECT_FACTS` 的「代码位置」登记了代码仓库根目录，运行时按本机项目根换算成绝对路径，下文记作 `<代码根>`（只在命令里用，不写进文件）。登记了多个就逐个做。所有命令都带 `<代码根>`，不依赖当前目录：两个工具不带路径时只认当前目录，在别处启动会话会查不到。

### 3. 排除不该进索引的目录，再建索引

先在 `<代码根>` 下写两份官方排除配置，内容相同，都是相对 `<代码根>` 的 gitignore 写法：

- `codegraph.json` 的 `exclude`（codegraph README「Configuration」：已提交进仓库的目录 `.gitignore` 挡不住，用它）；
- `.graphifyignore`（graphify 官方说明「Ignoring files」）。

要排除的：
- kb 挂在代码仓库里时，挂载目录（如 `kb/`）和 `.claude/`——不排除的话，方法论文档和 skill 脚本会进索引，实测 graphify 报告的 God Nodes 前几名全被 kb 文档占掉。
- `DATA_PROJECT_FACTS` 的「代码索引排除路径」（符号链接、生成副本等会让同一份代码出现两次的路径）。

```json
{ "exclude": ["kb/", ".claude/"] }
```

然后建索引：

```bash
codegraph init <代码根>
graphify update <代码根>
```

| | codegraph 符号索引 | graphify 代码图 |
|---|---|---|
| 生成 | `<代码根>/.codegraph/`（主体是 SQLite 数据库 `codegraph.db`） | `<代码根>/graphify-out/`（`graph.json` + `GRAPH_REPORT.md`） |
| 里面是什么 | 每个函数、类、方法定义在哪个文件哪一行，以及谁调用谁 | 代码按依赖关系聚成的一簇簇，每簇有哪些节点、哪些节点连接最多 |
| 流程里谁用 | 业务页代码锚点校验、顺锚点找代码、链路闭合核对 | 概览的「不遗漏核对」、业务初始化第 1 步圈出涉及的文件 |

- 两条都只在本地解析代码，不需要 API key，也不碰助手配置（实测：建索引前后扫描都为空，不留后台进程）。
- graphify 用 `update`，不用 `extract`：`extract` 只生成 `graph.json`，还要再跑一次 `cluster-only` 才有报告。`update` 用每簇里连接最多的符号给簇命名（如 `load_config`），流程要的 Community Hubs、God Nodes、Communities 三段齐全。
- `codegraph init` 在文件监听不可用的环境（如 WSL 的 `/mnt` 路径）会提议装 git hooks，默认是装；这只装刷新索引的 git hooks、不碰助手配置，装不装都行（见 `GOVERNANCE_TOOL_SETUP`「查询前先刷新」）。
- 把 `.codegraph/`、`graphify-out/` 加进 `<代码根>` 的 `.gitignore`。

### 4. 就绪检查

全部符合才算准备完成：

| 检查 | 命令 | 期望 |
|---|---|---|
| 命令行可用 | `codegraph --version`、`graphify --version` | 都输出版本号 |
| 两份索引已建 | `ls <代码根>/.codegraph <代码根>/graphify-out/GRAPH_REPORT.md` | 都存在 |
| 能查到符号 | `codegraph node "<项目里一个确定存在的函数名>" -p <代码根>` | 输出含 `**Location:**` |
| 排除生效 | `codegraph node "<kb 或 .claude 里的一个函数名>" -p <代码根>` | 输出含 `not found`（kb 不在代码仓库里就跳过） |
| 没接进助手 | `<扫描> all <启动 Claude Code 的目录>`；代码根不是这个目录的，对每个 `<代码根>` 也跑一次 | 输出为空 |
| 没有其他来源的 MCP | `claude mcp list` | 不含 codegraph（扫描不查插件和托管配置提供的 MCP，这条补上） |

**判「查不到」看输出，不看退出码**：符号不存在时 `codegraph node` 输出 `Symbol "..." not found in the codebase`，退出码仍是 0。

准备完成后，改了代码只需在查询前刷新（`GOVERNANCE_TOOL_SETUP`「查询前先刷新」），不用重建索引。

## 附：扫描有输出怎么清

只清 Claude Code 这一处。一个工具清完、扫描为空，再清下一个。

**遥测开启**：`codegraph telemetry off`。

**codegraph**（官方：`codegraph uninstall`「strips CodeGraph's MCP server config, instructions, and permissions」）：

```bash
codegraph uninstall --keep-cli -y --target claude                    # 全局；--keep-cli 必带，不带会连命令行一起卸掉
codegraph uninstall --keep-cli -y --target claude --location local   # 当前目录
```

- 扫描报 `~/.claude.json` 里 `projects[...].mcpServers.codegraph`（某个项目单独加的 MCP，上面两条不删）：到那个项目目录里跑 `claude mcp remove codegraph -s local`。
- 拆完剩「项目空壳」（安装时新建、现在只剩 `{}` 的 `.mcp.json` 等），删掉。

**graphify**（官方：「use the per-platform command (e.g. `graphify claude uninstall`)」；不用 `graphify uninstall`，它会连别的助手的配置和 git hooks 一起删）：

```bash
graphify claude uninstall                # 全局 skill、当前目录 CLAUDE.md 说明段、读前 hook
graphify claude uninstall --project      # 以项目为范围装过的：项目 .claude/skills/graphify/、.claude/CLAUDE.md 登记段
```

这两条拆不到、要手动清的（实测）：

- `~/.claude/CLAUDE.md` 里 `# graphify` 开头的三行登记段，整段删掉。
- `.claude/settings.json.graphify-bak`（写 hook 前留的旧 settings 备份），删掉。
- `.claude/settings.json` 里留下的空 `"hooks": {"PreToolUse": []}`：
  - 新建的（git 未跟踪），扫描报「项目空壳」，整个删掉；
  - git 跟踪的，graphify 会把整个文件重新排版，`git diff` 会显示整文件改动。按内容比较：`diff <(git show HEAD:.claude/settings.json | python3 -m json.tool --sort-keys) <(python3 -m json.tool --sort-keys .claude/settings.json)`，只差这段空 hooks 就 `git checkout -- .claude/settings.json` 还原；还有别的差异，就只手动删掉这段。

清完重跑 `<扫描>`，输出为空为止。
