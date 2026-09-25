# 步 6 · 组装

机械类。总则见 [`README.md`](./README.md)。

## 范围

**先查页是否已存在**(按标题/前缀 grep `DATA_BUSINESS` 下有无同前缀页;存在 → 不属于初始化范围,本流程到此停止,按 [`../README.md`](../README.md)"停止交回格式"交回入口分诊重新判断(如实报告"页已存在"这一事实,不由本流程自行断言应改走 update);不存在 → 按本步继续)。只吃 raw(步 3),按规则六节槽位填模板,生成 `DATA_BUSINESS` 下 `<业务>.md`——业务全貌图槽位、流程文字节各链路的图槽位,一律写标准真链接一行(写法见 `GOVERNANCE_RULES` 的 `diagram-rules.md` 五),链接目标为约定文件名(`DATA_IMAGES` 下 `<业务id>-overview.svg`、`<业务id>-<链路名>.svg`);**若该约定文件名当前不存在,机械复制 `sum-svg-diagram` skill 的 `assets/placeholder-pending.svg` 到该文件名占位**,不判断"要不要画"、不现画图、不改图。图的内容(占位 → 真图)由独立流程 [`../diagram-draw.md`](../diagram-draw.md) 负责,本步不涉及、不阻塞;页头基线 commit;`DATA_LOG` 追一行(格式见规则五);执行 [`../overview-sync.md`](../overview-sync.md) 同步 `ENTRY_OVERVIEW` 核心流程节对应 `kind:rule` 行;页面文件 + log 追加行 + 概览同步行 + 本批已落位的 SVG(占位或真图,取决于是否已先跑过 `diagram-draw.md`)与 raw 目录,在同一次 `git add <挂载根>` + `git commit` 里落地,提交由本步收口(执行者或编排者)在审查通过后一次性完成(不用 `kb.sh`,理由见 `GOVERNANCE_RULES` 的 `overview-rules.md` 八)。

## 产出

页(`DATA_BUSINESS` 下 `<业务>.md`)+ `ENTRY_OVERVIEW` 核心流程节对应 `kind:rule` 行同步(见 `GOVERNANCE_FLOW` 的 `overview-sync.md`)+ 同一次 git 提交。

## 注意

- **页头写 `tier:`**(`骨架` 或 `细节`,取值来自步 1/步 3 确定的档次,定义见 `GOVERNANCE_RULES` 的 `business-rule.md` 三)。
- **组装自查按档分叉**:
  - **骨架档**:走 `GOVERNANCE_RULES` 的 `business-rule.md` 三"骨架档三条"核对法(节点齐 / 连线齐 / 终态齐,含"合并自 N 处"字段是否齐),逐项与 raw 自查一致。
  - **细节档**:决策表节点数 / 编号分支行总数(逐节点列出)/ 共享前提条数 / 未闭合边界条数,逐项与 raw 自查一致。
  - 两档新增同一项——每条链路的图槽位**图链接存在且指向的 SVG 文件真实存在**(占位图或真图均算"存在",不区分);业务全貌图槽位同理。
- 不回头看代码、不做判断;槽位缺来源即停。
- 概览同步动作的范围/产出/注意/判据见 [`../overview-sync.md`](../overview-sync.md),本步只负责触发,不重复其判据。
- 页面文件、log 追加行、概览同步行三者是同一次提交,不拆开;提交前三者都要落盘完毕。
- **页头基线 commit 取值口径**:取本步组装落盘时仓库的 HEAD 短 sha,不是读代码/开始执行本流程那一刻的 commit;若组装期间发生过与本业务代码无关的提交(如本体系规则文档自身的修订),仍取当次 HEAD,不回溯——基线标注的是"这一页是对着哪个版本的仓库核过的",不是"业务代码最后一次改动"的时间点。

## 通过判据

"组装自查"节数字(含图槽位核对)与 raw 自查逐项一致;模板六节槽位无缺失(缺来源即停,视为不通过);每条链路的图槽位——**图链接行存在,且链接指向的 SVG 文件真实存在**,单一检查,无 OR 分支;业务全貌图槽位同理;页面文件 + log 追加行 + 概览同步行在同一次 git 提交里。

## 引用的规则条款

- 模板槽位(`GOVERNANCE_RULES` 的 `assembly-rules.md` 三)
- 硬规则 2(页面只显示在用;归档记录)(`GOVERNANCE_RULES` 的 `assembly-rules.md` 二.2)
- 硬规则 7(图槽位必占位,判断不入建页流程)、图落盘与引用(`GOVERNANCE_RULES` 的 `assembly-rules.md` 二.7、`GOVERNANCE_RULES` 的 `diagram-rules.md` 五)
- 出图独立流程(`GOVERNANCE_FLOW` 的 `diagram-draw.md`)、占位资产来源(`sum-svg-diagram` skill `assets/placeholder-pending.svg`)
- log 记录规则(`GOVERNANCE_RULES` 的 `assembly-rules.md` 五)
- 概览同步动作(`GOVERNANCE_FLOW` 的 `overview-sync.md`)、提交统一(`GOVERNANCE_RULES` 的 `overview-rules.md` 八)
