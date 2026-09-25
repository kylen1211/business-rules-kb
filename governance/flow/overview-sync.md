# 全局概览 · 组装收尾同步动作

> 业务规则页任意一次组装通过校验后执行——初始化见 [`./init/step6-assemble.md`](./init/step6-assemble.md)。
> 规则依据见 [`../rules/overview-rules.md`](../rules/overview-rules.md) 四。

## 范围

检查 `ENTRY_OVERVIEW` 核心流程节里对应本次组装业务的 `kind:rule` 行的 `page`/`tier` 字段:

- 该行当前 `page:none; tier:none`(页尚未建)→ 把注释改成 `page:data/business/<业务id>.md; tier:<骨架|细节>`(取值与新建页内 frontmatter 的 `tier:` 字段同值),并把可见文本的中文名称从纯文字改成指向该业务页的 Markdown 链接(`[<中文名称>](<page 相对路径>)`,格式见 `GOVERNANCE_RULES` 的 `overview-rules.md` 四);描述文字本身不变,除非新页的 `title` 与该行原有的中文名称不一致——不一致则按规则四"中文业务名的取法"用新页 `title` 更新可见名称(链接目标仍取新 `page` 路径)。
- 该行 `page` 已指向某业务页、本次组装是升档(骨架→细节)→ 把 `tier` 字段改成升档后页内 frontmatter 的新值,`page` 字段不变,可见文本链接不变。
- 该行 `page`/`tier` 字段已与页内 frontmatter 同值 → 无需改动。
- 完全没有该行(核心流程节里尚无对应本业务的 `kind:rule` 行)→ 按规则四格式新增一行(`page`/`tier` 取新建页的实际值,中文名称即为可点击链接)。

## 产出

`ENTRY_OVERVIEW` 核心流程节对应 `kind:rule` 行的 `page`/`tier` 字段更新(或确认无需更新)。

## 注意

- 只改本次组装涉及的那一行,不顺手改其它行。
- 组装未通过校验 → 不执行本动作,`ENTRY_OVERVIEW` 不发生任何变化。
- 并发/批次冲突沿用现有硬规则"批次按 commit 串行,先来先改"(`GOVERNANCE_RULES` 的 `assembly-rules.md` 二.4),不额外加锁。
- 回退:组装被判不通过或事后要撤销,本动作本就未执行或随该次改动一起回退,不需要单独的概览回滚步骤。
- **提交统一(`GOVERNANCE_RULES` 的 `overview-rules.md` 八)**:本动作产生的 `ENTRY_OVERVIEW` 改动,与本次组装产生的业务页文件改动、`DATA_LOG` 追加行,三者在同一次 `git add <挂载根>` + `git commit` 里完成,不使用 `kb.sh`,不拆成多次提交。

## 通过判据

- Given 某业务规则页刚完成一次组装且通过校验,When 检查同一次改动,Then `ENTRY_OVERVIEW` 中该业务对应 `kind:rule` 行的 `page`/`tier` 字段与页内 frontmatter 同值,且该行改动、业务页文件改动、log 追加行三者在同一次 `git commit` 里。
- Given 组装未通过校验,When 检查 `ENTRY_OVERVIEW`,Then 不发生任何变化。

## 引用的规则条款

- 核心流程 `kind:rule` 行写法(`GOVERNANCE_RULES` 的 `overview-rules.md` 四)、提交统一(八)
- 批次串行(`GOVERNANCE_RULES` 的 `assembly-rules.md` 二.4)
