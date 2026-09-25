# AGENTS.md —— 治理入口

本文件是本体系的治理契约入口页,一行一条指引:

- **挂载根声明**:本体系当前挂载在项目仓库的 `kb/` 目录下(即 MOUNT_ROOT,定义见 `governance/PATHS.md`——本行是找到该表的唯一入口,除此之外体系内正文不再直接书写字面路径)。换项目、换挂载位置、或调整内部目录结构,只改 `governance/PATHS.md` 对应行,不需要排查全库旧写法。体系内正文引用体系内文件/目录一律用路径表里的逻辑名(如 `DATA_BUSINESS`、`GOVERNANCE_RULES`)指代;真实 Markdown 超链接例外,一律写可解析的字面路径(渲染器不认识逻辑名),正确性由链接检查工具核对。
- 页格式看 `GOVERNANCE_RULES` 的 `business-rule.md`;流程判据、模板槽位、log 记录规则看 `GOVERNANCE_RULES` 的 `assembly-rules.md`;图的风格与产出规范看 `GOVERNANCE_RULES` 的 `diagram-rules.md`(本体系全部图统一规范,业务链路局部图 + 业务全貌图 + 全局业务图 + 全局架构图)。
- **进哪条流程由 `GOVERNANCE_FLOW` 的 `README.md`("入口分诊")统一裁决,三条流程(初始化/更新/概览)内部不互相转介**——业务规则初始化按 `GOVERNANCE_FLOW_INIT` 五步执行(出图已独立成 `GOVERNANCE_FLOW` 的 `diagram-draw.md`,不占编号)、业务规则更新按 `GOVERNANCE_FLOW_UPDATE` 六步执行,具体分诊判据、每条流程的起点与触发源见该文件。
- **走任何流程之前**,先完成准备阶段 `GOVERNANCE_PREPARE`(装代码查询工具、建索引);它不属于流程,不产出 kb 数据。
- **项目首次挂载本体系(或体系版本升级后需要重新核对适配数据)**,先走一次性前置阶段 `GOVERNANCE_FLOW_SETUP`(挂载根确认 + 项目适配事实卡,产出 `DATA_PROJECT_FACTS`)——这一步只产出项目专属**数据**,不改 `GOVERNANCE_RULES`/`GOVERNANCE_FLOW` 下任何方法论文件正文;三条常规流程(初始化/更新/概览)在该阶段完成前不具备执行前提,完成后除非体系升级要求重新核对,不需要重跑。
- 全局概览(`ENTRY_OVERVIEW`)的结构与判据看 `GOVERNANCE_RULES` 的 `overview-rules.md`;首次生成/重建按 `GOVERNANCE_FLOW` 的 `overview-init.md`(一次性);业务页任意一次组装通过校验后的同步动作见 `GOVERNANCE_FLOW` 的 `overview-sync.md`。
- 以上三套流程(概览初始化 / 业务初始化 / 业务更新)相互独立,不互相引用作业方法,只共用本页列出的格式与判据规则。
- 图片统一放 `DATA_IMAGES`(svg 优先),正文不内嵌图,只在对应位置留一行链接。嵌图页包括 `ENTRY_OVERVIEW` 与 `DATA_BUSINESS` 下的各业务页,各页物理位置不同、到 `DATA_IMAGES` 的相对路径深度也不同,写法统一为:`👉 [点击打开 <图名>.svg](<该页到 DATA_IMAGES 的相对路径>/<图名>.svg)`;一律用相对路径,不写绝对路径或 `file://`,具体相对深度按各页实际位置手算,以链接检查通过为准。
- **commit 与事后事实记法**:记录本体系新增数据/变更的字段,若其值恰好等于该记录自身所在的这次提交(如 `DATA_LOG` 自由命名类型条目的 `commit:` 字段)——这类值在写下这行文字的那一刻尚不存在(git commit hash 是所在提交树内容的函数,同一次提交内的文件无法正确预写自己的哈希),一律用自指写法(如"与本条同次提交入库"),不得用"未提交/待补/由某人收口"一类需要日后单独编辑回填的占位表述;真实提交号事后可从 `git log` 该文件反查,不丢信息。**此条款不适用于**值在写入当下已经存在、此后不再变的字段(如业务页页头"验证基线 commit"、`rule-init`/`rule-update`/`rule-retire` 三个专属 type 的 `commit:` 字段,定义见 `GOVERNANCE_RULES` 的 `assembly-rules.md` 5.3——那是写入当下已知的 HEAD 短 sha,不是对本次提交自身的预测);这类字段照常直接填真实值。
- **治理性修订的传导与重审义务**:改动本体系任一文件(`GOVERNANCE_RULES` 下的规则文件 / `DATA_LESSONS` / `DATA_LOG` / `DATA_BUSINESS` 下的业务页)时——若依据是对某次拍板或历史结论的**纠正**(认定旧结论当时就错了,如误读被回归本意),收尾前须回查该结论的原始出处(`agent-mem recall`/原会话记录,不能只凭转述文本)确认新口径准确,并排查该旧结论的全部派生记录(`DATA_LESSONS` 案例、`DATA_LOG` 条目、`GOVERNANCE_RULES` 正文、受影响的 `DATA_BUSINESS` 下业务页)同步改口径,遗漏视为本次纠正未完成;若依据是判据本身**扩展了覆盖范围**(旧结论在旧判据下并不算错,只是新判据能覆盖更多情形,如提示词驱动因果判据出台前后对链路独立性的判断),不要求当场重跑旧结论,在 `DATA_LESSONS` 对应案例结论段标注受影响的已建业务页与待重审时机即可(标注时统一带上“待新判据重审”字样,便于日后按此关键词核对),留待该业务下次自然进入 `GOVERNANCE_FLOW_UPDATE` 时由起草人核对处理。
- **判据的定义处放哪里**:跨流程复用的判据放 `GOVERNANCE_RULES`;单流程专属、只被该流程内部步骤引用的判据,可以就近定义在该流程的收口步骤文件里,但须显式声明"本节是该判据的唯一定义处"(如 `GOVERNANCE_FLOW_UPDATE` 的 `step6-assemble.md`"分流判据"一节),供同流程其他步骤(如 `step4-classify.md`)直接引用而不重复定义、不各自解释。
