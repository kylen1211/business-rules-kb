# 步 6 · 组装

机械类。骨架档、细节档都走。不回头看代码、不做判断；槽位缺来源即停。

## 范围

1. **先查页是否已存在**（按标题/前缀 grep `DATA_BUSINESS` 下有无同前缀页）。存在 → 不属于初始化范围，本步到此停止，回执报「停止」并如实写「页已存在」和那一页的路径，不自行断言该改走更新；不存在 → 继续。
2. 只吃 raw（批次目录 `step3-raw.md`），按 `GOVERNANCE_RULES` 的 `business-rule.md` 二的六节槽位与 `assembly-rules.md` 三的模板，生成 `DATA_BUSINESS` 下 `<业务id>.md`（目录不存在就建）。
3. **图槽位**：业务全貌图槽位、流程文字节各链路的图槽位，一律写标准真链接一行（写法见 `GOVERNANCE_RULES` 的 `diagram-rules.md` 五），链接目标为约定文件名（`DATA_IMAGES` 下 `<业务id>-overview.svg`、`<业务id>-<链路名>.svg`）。`DATA_IMAGES` 目录不存在就建。约定文件名当前不存在的，**机械复制项目里 `.claude/skills/sum-svg-diagram/assets/placeholder-pending.svg` 到该文件名占位**，不判断「要不要画」、不现画图、不改图。
4. **页头基线 commit**：取**代码根所在仓库**本步组装落盘时的 HEAD 短 sha（`git -C <代码根> rev-parse --short HEAD`；代码根就是项目根时即项目仓库的 HEAD；登记了多个代码根的，写成 `<名称>@<sha>` 逐个列出），不是读代码/开始执行那一刻的 commit；组装期间有与本业务无关的提交，仍取当次 HEAD，不回溯——基线标注的是「这一页是对着哪个版本的仓库核过的」。
5. **`DATA_LOG` 追一行**：`rule-init` 类型，`commit:` 字段与页头基线同值，格式与位置见 `GOVERNANCE_RULES` 的 `assembly-rules.md` 五（新条目插在 `# Wiki Log` 标题正下方，同时把 frontmatter 的 `updated` 刷成当天）。`DATA_LOG` 不存在时新建，内容如下，再按上面追加：

   ```markdown
   ---
   type: meta
   title: Wiki Log
   status: evergreen
   created: <当天>
   updated: <当天>
   tags:
     - meta
     - log
   ---

   # Wiki Log

   Newest completed operations appear first.
   ```

6. **概览同步**：`有概览` 时按 `GOVERNANCE_FLOW` 的 `overview-sync.md` 同步 `ENTRY_OVERVIEW` 核心流程节对应的 `kind:rule` 行；`无概览` 时跳过，不新建概览。
7. 不提交。所有文件落盘后交回，提交由编排者统一做。

## 产出

业务页（`DATA_BUSINESS` 下 `<业务id>.md`）+ `DATA_LOG` 追加行 + 占位 SVG +（`有概览` 时）概览同步行，全部落盘、未提交。

## 注意

- **页头写 `tier:`**（`骨架` 或 `细节`，取值来自步 1/步 3 确定的档次，定义见 `GOVERNANCE_RULES` 的 `business-rule.md` 三）。
- **组装自查按档分叉**：
  - **骨架档**：走 `business-rule.md` 三「骨架档三条」核对法（节点齐 / 连线齐 / 终态齐，含「合并自 N 处」字段是否齐），逐项与 raw 自查一致。
  - **细节档**：决策表节点数 / 编号分支行总数（逐节点列出）/ 共享前提条数 / 未闭合边界条数，逐项与 raw 自查一致。
  - 两档都查：每条链路的图槽位**图链接存在且指向的 SVG 文件真实存在**（占位图或真图均算「存在」）；业务全貌图槽位同理。

## 通过判据

「组装自查」节数字（含图槽位核对）与 raw 自查逐项一致；模板六节槽位无缺失（缺来源即停，视为不通过）；每条链路的图槽位——**图链接行存在，且链接指向的 SVG 文件真实存在**，单一检查，无 OR 分支；业务全貌图槽位同理。

## 引用的规则条款

- 模板槽位（`GOVERNANCE_RULES` 的 `assembly-rules.md` 三）
- 硬规则 2（页面只显示在用；归档记录）（`GOVERNANCE_RULES` 的 `assembly-rules.md` 二.2）
- 硬规则 7（图槽位必占位，判断不入建页流程）、图落盘与引用（`GOVERNANCE_RULES` 的 `assembly-rules.md` 二.7、`diagram-rules.md` 五）
- log 记录规则（`GOVERNANCE_RULES` 的 `assembly-rules.md` 五）
- 概览同步动作（`GOVERNANCE_FLOW` 的 `overview-sync.md`，仅 `有概览`）

## 回执

- 停止时：「停止」+ 依据（如「页已存在：<路径>」），其余不填
- 落盘的文件清单
- 组装自查：逐项数字，并注明与 raw 是否一致
- 图槽位：每个槽位的 SVG 路径，是占位还是真图
- 页头基线 commit、log 追加的那一行原文
- 不确定项：缺来源而停下的槽位
