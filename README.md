# 业务规则知识库 · 方法论

把项目的业务逻辑整理成「条件→结果」的规则清单，作为需求、开发、测试共同对齐的统一标准源。原理和用法见 [`governance/README.md`](governance/README.md)。

本仓库只放方法论（规则、流程、画图规范），不放任何项目的业务数据。数据在挂载它的项目里自己长出来。

## 目录

| 路径 | 内容 |
|---|---|
| `governance/` | 方法论本体：`rules/` 页格式与判据，`flow/` 初始化 / 更新 / 概览 / 出图流程，`PATHS.md` 路径表，`AGENTS.md` 治理入口，`prepare.md` 准备阶段（装命令行、建索引），`scripts/tool-residue-scan.sh` 残留扫描，`tool-setup.md` 工具说明与日常使用 |
| `.claude/skills/sum-svg-diagram/` | 画图 skill（两张骨架母版 + 几何自检脚本），`governance/rules/diagram-rules.md` 按它出图 |
| `.claude/skills/business-rule-init/` | 单条业务规则初始化 skill（手动调用 `/business-rule-init`）：步骤取自 `governance/flow/init/`，每步派子代理执行，不需要先建全局概览 |

## 前置工具

流程核对规则和代码时要用两个命令行工具：[codegraph](https://github.com/colbymchenry/codegraph)（符号查询）和 [graphify](https://github.com/Graphify-Labs/graphify)（代码聚簇）。**只装命令行，不接进 AI 助手。**装命令行、建索引、就绪检查见 [`governance/prepare.md`](governance/prepare.md)；为什么不接进助手、日常刷新见 [`governance/tool-setup.md`](governance/tool-setup.md)。

## 挂到一个项目里

1. 按 [`governance/prepare.md`](governance/prepare.md) 第一部分装两个工具的命令行（每台机器一次；一个一个装，每装一个扫描一次，扫描脚本从本仓库克隆目录运行）。
2. 把 `governance/` 复制到项目的 `kb/governance/`，项目自己的数据放 `kb/data/`（首次挂载时为空）。
3. 把 `.claude/skills/sum-svg-diagram/`、`.claude/skills/business-rule-init/` 复制到项目的 `.claude/skills/` 下。
4. 挂载位置不是 `kb/` 的，改 `governance/PATHS.md` 里 `MOUNT_ROOT` 一行。
5. 走一次 `governance/flow/project-setup.md`（项目适配，一次性），其中登记「代码位置」：业务代码所在仓库的根目录。
6. 按 `governance/prepare.md` 第二部分，在登记的代码位置建索引、跑就绪检查。之后按 `governance/flow/README.md` 分诊进各条流程，或直接用 `/business-rule-init` 初始化单条业务规则。

## 来源

从 voice-agent 项目（私有）的 `kb/governance/` 与 `.claude/skills/sum-svg-diagram/` 拆出（该项目提交 `177550e`），此前的修改历史不随迁。
