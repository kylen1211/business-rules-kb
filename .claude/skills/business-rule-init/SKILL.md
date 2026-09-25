---
name: business-rule-init
description: 单独初始化一条业务规则页（骨架档或细节档），不需要先建全局概览。步骤取自 governance/flow/init/，每步派一个子代理执行。
disable-model-invocation: true
---

# business-rule-init · 单条业务规则初始化

把一个业务从代码整理成一张业务规则页。步骤与 `GOVERNANCE_FLOW_INIT` 一致，单独抽出来，项目没有全局概览也能跑。本会话是**编排者**：只串联步骤、转交产物、等人审，自己不读业务代码、不写产物。

## 输入

- **业务**：用户给的业务名或入口（函数、文件、功能描述均可）。
- **tier**：`骨架` 或 `细节`，用户没说就用 `骨架`（`GOVERNANCE_RULES` 的 `business-rule.md` 三：初始化一律先做骨架档，明确需要细节时才做细节档）。

## 前提

逐条确认，不满足就停下告诉用户缺什么：

1. **挂载根**：读项目里的 `kb/governance/PATHS.md`（挂载位置不是 `kb/` 的，以用户说的为准），取 `MOUNT_ROOT`。下文逻辑名都按这张表解析。
2. **项目适配已完成**：`DATA_PROJECT_FACTS` 存在。没有就让用户先走 `GOVERNANCE_FLOW_SETUP`。
3. **概览在不在**：看 `ENTRY_OVERVIEW` 是否存在，记为 `有概览` / `无概览`，派步 1 和步 6 时传下去。

## 步 0 · 工具准备

本会话在项目根目录自己做，命令和期望值都在 `GOVERNANCE_PREPARE`：

1. **命令行**：`codegraph --version`、`graphify --version`。缺哪个就停下，把 `GOVERNANCE_PREPARE` 第 1、2 步给用户，由用户按顺序一个一个装，不替用户安装。
2. **没接进助手**：跑 `GOVERNANCE_TOOL_SCAN all .`。有输出就停下，把输出和 `GOVERNANCE_PREPARE`「附：以前接入过助手，或扫描有输出」转给用户，清干净再继续——这些改的是用户的全局配置，不替用户改。
3. **索引**：`.codegraph/` 或 `graphify-out/GRAPH_REPORT.md` 缺哪份，就按 `GOVERNANCE_PREPARE` 第 3 步建哪份（`codegraph init .` / `graphify update .`），并确认两个目录在 `.gitignore` 里。
4. **刷新**：两份都在的，查询前刷到当前代码：`codegraph sync .`、`graphify update .`。
5. **就绪检查**：按 `GOVERNANCE_PREPARE` 第 4 步逐条执行。

全部符合才派步 1。结果（版本号、建了还是刷新了哪份索引、检查逐条结论）写进最后给用户的汇报。

## 步骤

| tier | 走哪几步 |
|---|---|
| 骨架 | 步 0 → 步 1 → 步 3 → 步 6 |
| 细节 | 步 0 → 步 1 → 步 2 → 步 3 → 步 4 → 步 6 |

编号沿用原流程，没有步 5（出图已独立成 `diagram-draw`，本 skill 不出图，图槽位放占位图）。

每一步派一个**新的**子代理（`general-purpose`），上下文不混。派发时照下面的模板写，按表选模型：

| 步 | 说明文件 | 性质 | 模型 |
|---|---|---|---|
| 步 1 概览 | `steps/step1-overview.md` | 判断 | 默认（不填） |
| 步 2 提取 | `steps/step2-extract.md` | 机械 | `sonnet` |
| 步 3 归纳 | `steps/step3-classify.md` | 判断 | 默认（不填） |
| 步 4 校验 | `steps/step4-verify.md` | 机械，必须和步 3 不是同一个子代理 | `sonnet` |
| 步 6 组装 | `steps/step6-assemble.md` | 机械 | `sonnet` |

派发模板：

```
读 <本 skill 目录>/steps/<说明文件>，只做这一步。
- 项目根：<绝对路径>；MOUNT_ROOT：<值>，逻辑名按 <MOUNT_ROOT>governance/PATHS.md 解析
- 业务：<业务名或入口>；tier：<骨架|细节>；概览：<有概览|无概览>
- 批次目录：<DATA_BUSINESS_RAW 解析后的路径>/init-<业务id>/（步 1 定出业务前缀后才有 id，步 1 用用户给的业务名的英文短名）
- 前面步骤的产物：<批次目录下已有的文件>
做完按说明文件末尾的「回执」格式交回。
```

## 每步之后

- **步 1**：把产物和回执原样转给用户，**等用户审核通过**才进下一步。用户要改的，派新的步 1 子代理带着意见重做。
- **其他步**：回执里「不确定项」为空就直接进下一步；不为空就转给用户，等用户定了再继续。
- **步 4 不通过**：把不通过清单交给一个新的步 3 子代理重做，再派一个新的步 4 子代理复核；每轮都告诉用户。
- **任一步回执报「停止」**（如步 6 发现页已存在）：本 skill 到此结束，把停止依据原样转给用户，不自行改走别的流程（已存在的页该走更新还是升档，由用户按 `GOVERNANCE_FLOW` 的 `README.md` 判断）。

## 收尾（步 6 回执通过后）

1. 核对步 6 回执里的「组装自查」数字与 raw 一致、图槽位指向的 SVG 都存在。
2. 在项目里一次提交：`git add <MOUNT_ROOT>` + `git commit`，内容是业务页、`DATA_LOG` 追加行、占位 SVG、批次目录（`有概览` 时还有概览同步行）。
3. 向用户汇报：业务页路径、tier、各步的不确定项怎么定的；图目前是占位，要出真图走 `GOVERNANCE_FLOW` 的 `diagram-draw.md`。
