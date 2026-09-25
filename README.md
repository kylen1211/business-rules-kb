# 业务规则知识库 · 方法论

把项目的业务逻辑整理成「条件→结果」的规则清单，作为需求、开发、测试共同对齐的统一标准源。原理和用法见 [`governance/README.md`](governance/README.md)。

本仓库只放方法论（规则、流程、画图规范），不放任何项目的业务数据。数据在挂载它的项目里自己长出来。

## 目录

| 路径 | 内容 |
|---|---|
| `governance/` | 方法论本体：`rules/` 页格式与判据，`flow/` 初始化 / 更新 / 概览 / 出图流程，`PATHS.md` 路径表，`AGENTS.md` 治理入口 |
| `.claude/skills/sum-svg-diagram/` | 画图 skill（两张骨架母版 + 几何自检脚本），`governance/rules/diagram-rules.md` 按它出图 |

## 挂到一个项目里

1. 把 `governance/` 复制到项目的 `kb/governance/`，项目自己的数据放 `kb/data/`（首次挂载时为空）。
2. 把 `.claude/skills/sum-svg-diagram/` 复制到项目的 `.claude/skills/sum-svg-diagram/`。
3. 挂载位置不是 `kb/` 的，改 `governance/PATHS.md` 里 `MOUNT_ROOT` 一行。
4. 先走一次 `governance/flow/project-setup.md`（项目适配，一次性），之后按 `governance/flow/README.md` 分诊进各条流程。

## 来源

从 voice-agent 项目（私有）的 `kb/governance/` 与 `.claude/skills/sum-svg-diagram/` 拆出（该项目提交 `177550e`），此前的修改历史不随迁。
