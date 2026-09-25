---
name: business-rule-init
description: 单独初始化一条业务规则页（骨架档或细节档），不需要先建全局概览。步骤取自 governance/flow/init/，每步派一个子代理执行。
disable-model-invocation: true
---

# business-rule-init · 单条业务规则初始化

把一个业务从代码整理成一张业务规则页。步骤与 `GOVERNANCE_FLOW_INIT` 一致，单独抽出来，项目没有全局概览也能跑。本会话是**编排者**：只串联步骤、转交产物、等人审，自己不读业务代码、不写产物。

## 输入

- **业务**：用户给的业务名或入口（函数、文件、功能描述均可）。
- **业务 id**：英文短名、小写连字符（如 `task-dispatch`），用作页面文件名 `<业务id>.md`、批次目录 `init-<业务id>/`、图文件名前缀。开跑时和用户定下，全程不变。它不是页头的「编号前缀」（如 `TASKDISPATCH`），编号前缀由步 1 定。
- **tier**：`骨架` 或 `细节`，用户没说就用 `骨架`（`GOVERNANCE_RULES` 的 `business-rule.md` 三：初始化一律先做骨架档，明确需要细节时才做细节档）。

## 步 -1 · 登记路径

本会话先确认三个路径，**每次都做、都给用户确认**：

1. **项目根**：当前目录所在 git 仓库的根（`git rev-parse --show-toplevel`）。kb 挂在这个仓库里，最后的提交也落在这里。
2. **挂载根**：读 `<项目根>/kb/governance/PATHS.md` 的 `MOUNT_ROOT`；挂载位置不是 `kb/` 的，以用户说的为准。之后的逻辑名都按这张表解析。
3. **代码位置**：`DATA_PROJECT_FACTS` 里有「代码位置」就用它；没有就默认取 `.`（代码和 kb 同在项目根），给用户确认或改。把每个路径换算成绝对路径，记为 `<代码根>`，确认都存在。之后所有 codegraph / graphify 命令都带它（`GOVERNANCE_RULES` 的 `business-rule.md`「codegraph 查询口径」）。

然后看 `DATA_PROJECT_FACTS`：不存在或六项有缺 → 派一个子代理执行 `steps/step-setup.md`（模型 `sonnet`，派发时带上已确认的代码位置），把写入的六项转给用户确认，要改的派新的子代理带着意见重做。六项齐全 → 跳过。

最后确认两项：

- **占位图**：`<项目根>/.claude/skills/sum-svg-diagram/assets/placeholder-pending.svg` 存在（步 6 要复制它占图槽位）。没有就停下，让用户先把画图 skill 复制进项目。
- **概览在不在**：看 `ENTRY_OVERVIEW` 是否存在，记为 `有概览` / `无概览`，派步 1 和步 6 时传下去。

## 步 0 · 工具准备

本会话自己做，命令和期望值都在 `GOVERNANCE_PREPARE`；登记了多个代码根的，第 3–5 条逐个代码根做：

1. **命令行**：`codegraph --version`、`graphify --version`。缺哪个就停下，把 `GOVERNANCE_PREPARE` 第一部分给用户，由用户一个一个装，不替用户安装。
2. **没接进助手**：跑 `GOVERNANCE_TOOL_SCAN all <项目根>`，代码根不是项目根的，对每个 `<代码根>` 也跑一次。有输出就停下，把输出和 `GOVERNANCE_PREPARE`「附：扫描有输出怎么清」转给用户，清干净再继续——这些改的是用户的配置，不替用户改。
3. **索引**：`<代码根>/.codegraph/` 或 `<代码根>/graphify-out/GRAPH_REPORT.md` 缺哪份，就按 `GOVERNANCE_PREPARE` 第 3 步建哪份（先确认排除配置已写，再 `codegraph init <代码根>` / `graphify update <代码根>`）。
4. **刷新**：第 3 条没有新建的那份，刷到当前代码：`codegraph sync <代码根>`、`graphify update <代码根>`。
5. **就绪检查**：按 `GOVERNANCE_PREPARE` 第 4 步逐条执行。

全部符合才派步 1。结果（版本号、建了还是刷新了哪份索引、检查逐条结论）写进最后给用户的汇报。

## 步骤

| tier | 走哪几步 |
|---|---|
| 骨架 | 步 -1 → 步 0 → 步 1 → 步 3 → 步 6 |
| 细节 | 步 -1 → 步 0 → 步 1 → 步 2 → 步 3 → 步 4 → 步 6 |

编号沿用原流程：步 -1、步 0 是本 skill 补的前置（登记路径、工具准备），没有步 5（出图已独立成 `diagram-draw`，本 skill 不出图，图槽位放占位图）。

每一步派一个**新的**子代理（`general-purpose`），上下文不混。派发时照下面的模板写，按表选模型：

| 步 | 说明文件 | 性质 | 模型 |
|---|---|---|---|
| 步 -1 事实登记（按需） | `steps/step-setup.md` | 盘点 | `sonnet` |
| 步 1 概览 | `steps/step1-overview.md` | 判断 | 默认（不填） |
| 步 2 提取 | `steps/step2-extract.md` | 机械 | `sonnet` |
| 步 3 归纳 | `steps/step3-classify.md` | 判断 | 默认（不填） |
| 步 4 校验 | `steps/step4-verify.md` | 机械，必须和步 3 不是同一个子代理 | `sonnet` |
| 步 6 组装 | `steps/step6-assemble.md` | 机械 | `sonnet` |

派发模板：

```
读 <本 skill 目录>/steps/<说明文件>，只做这一步。
- 项目根：<绝对路径>；MOUNT_ROOT：<值>，逻辑名按 <MOUNT_ROOT>governance/PATHS.md 解析
- 代码根：<每个代码根的绝对路径>；codegraph / graphify 命令一律带它（-p <代码根>、sync/update <代码根>），报告读 <代码根>/graphify-out/GRAPH_REPORT.md
- 业务：<业务名或入口>；tier：<骨架|细节>；概览：<有概览|无概览>
- 业务 id：<业务id>；批次目录：<DATA_BUSINESS_RAW 解析后的路径>/init-<业务id>/（不存在就建）
- 前面步骤的产物：<批次目录下已有的文件>
做完按说明文件末尾的「回执」格式交回。
```

## 每步之后

- **步 1**：把产物和回执原样转给用户，**等用户审核通过**才进下一步。用户要改的，派新的步 1 子代理带着意见重做。
- **其他步**：回执里「不确定项」为空就直接进下一步；不为空就转给用户，等用户定了再继续。
- **步 3 回执报步 2 漏了出口**（仅细节档）：派新的步 2 子代理带着漏掉的出口补提取，再派新的步 3 子代理重做归纳。
- **步 4 不通过**：把不通过清单交给一个新的步 3 子代理重做，再派一个新的步 4 子代理复核；每轮都告诉用户。
- **任一步回执报「停止」**（如步 6 发现页已存在）：本 skill 到此结束，把停止依据原样转给用户，不自行改走别的流程（已存在的页该走更新还是升档，由用户按 `GOVERNANCE_FLOW` 的 `README.md` 判断）。

## 收尾（步 6 回执通过后）

1. 核对步 6 回执里的「组装自查」数字与 raw 一致、图槽位指向的 SVG 都存在。
2. 在项目根一次提交：`git add <MOUNT_ROOT>` + `git commit`，内容是业务页、`DATA_LOG` 追加行、占位 SVG、批次目录（步 -1 新建或补了事实卡的，事实卡一起；`有概览` 时还有概览同步行）。
3. 向用户汇报：业务页路径、tier、各步的不确定项怎么定的；图目前是占位，要出真图走 `GOVERNANCE_FLOW` 的 `diagram-draw.md`。
