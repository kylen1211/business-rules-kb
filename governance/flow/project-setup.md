# 项目适配初始化 · 前置阶段(一次性)

> 治理入口见 `ENTRY_AGENTS`;入口分诊见 `GOVERNANCE_FLOW` 的 `README.md`(本阶段是分诊判据的执行前提,不占分诊编号)。
> 用于本体系**首次挂载到某个项目**,或体系版本升级后需要重新核对适配数据。
> **本阶段只产出项目专属数据,产出位置是 `DATA_PROJECT_FACTS`(定义见 `ENTRY_PATHS`),不改动 `GOVERNANCE_RULES`/`GOVERNANCE_FLOW` 下任何方法论文件正文**——这是本阶段存在的唯一理由:换项目时只需要在这里填一次数据,不需要回头编辑规则/流程文件本身(此前挂载新项目时曾出现过手改 `overview-rules.md`/`overview-exclude.md`/流程文件正文才能用的情形,本阶段是对该问题的直接修复)。
> **前提**:已完成准备阶段 `GOVERNANCE_PREPARE` 第一部分(装命令行)。本阶段登记的「代码位置」是其第二部分(建索引)的输入;本阶段完成后做第二部分,再进三条常规流程。准备阶段不属于流程,本阶段不做、不检查。
> 完成本阶段前,三条常规流程(业务初始化 `GOVERNANCE_FLOW_INIT`、业务更新 `GOVERNANCE_FLOW_UPDATE`、概览初始化 `overview-init.md`)均不具备执行前提;完成后除非体系版本升级要求重新核对,不需要重跑。

共一步(判断类,信息充分时可一次做完;信息不全时允许分批补齐,见"注意")。

## 步骤 · 挂载确认与项目事实收集

### 范围

1. **挂载根确认**:核对 `ENTRY_PATHS` 的 `MOUNT_ROOT` 是否与本项目实际挂载位置一致;不一致则改这一行(`ENTRY_PATHS` 本身已保证这一处改动不需要全库排查旧写法),一致则原样确认,不需要额外动作。
2. **项目事实收集**,盘点以下三项作为后续三条常规流程要引用的基础事实(不做分类判断,只记录客观事实):
   - **项目名**:取仓库目录名或承载文档自称的项目名,与 `overview-rules.md` 一节的项目名取法一致,不另立第二套取法。
   - **主语言 / 运行时**:如实记录(可以是多个,如"TypeScript/Node ESM + 若干 Python 脚本"),不强行归一成一种。
   - **标准排除句用词清单**:业务代码调用、但内部实现不需要本体系索引的第三方框架/运行时/SDK 具体名称(如某项目的 Node 运行时、MCP SDK;另一项目的 Python asyncio、pipecat)——供 `GOVERNANCE_FLOW_INIT` 的 `step1-overview.md`、`GOVERNANCE_FLOW_UPDATE` 的 `step3-extract.md` 里的标准排除句直接引用取值,不必每次重新论证具体该写哪个框架名。
   - **代码位置**:业务代码所在仓库的根目录,写相对挂载所在仓库根的路径(代码与 kb 同仓写 `.`;不写绝对路径,换机器或换克隆位置时不用改;代码在另一个仓库时写 `../<仓库名>` 这类相对路径,各机器上两个仓库的相对位置要一致);代码分在多个仓库就逐行列出,每行 `<名称>: <路径>`。codegraph/graphify 的建索引与全部查询都按它带路径执行(不带路径时两个工具只认当前目录),用法见 `GOVERNANCE_RULES` 的 `business-rule.md`「codegraph 查询口径」。
   - **代码索引排除路径**:会让同一份代码被索引两次的路径(符号链接、生成副本等),建索引时写进官方排除配置(见 `GOVERNANCE_PREPARE` 第 3 步);没有就写「无」。查法:`find . \( -name .git -o -name node_modules -o -name .venv \) -prune -o -type l -print` 找出指向项目内代码的符号链接。
3. 写入 `DATA_PROJECT_FACTS`(新建或覆盖),字段固定六项:项目名 / 主语言运行时 / 标准排除句用词清单 / 代码位置 / 代码索引排除路径 / 完成日期。

### 产出

`DATA_PROJECT_FACTS` 文件(新建或覆盖)+ `ENTRY_PATHS` 的 `MOUNT_ROOT` 行确认或更新结果。

### 注意

- **本阶段不判断核心流程具体有哪些环节与配件行**——那是 `overview-init.md` 步 1 盘点的事(按 `overview-rules.md` 四·4.2/4.3 的判据逐项核实);本阶段只交出"这个项目是什么"的基础事实,不越权做分类判断,避免两处产生互相打架的结论。
- 项目事实收集出现不确定时(如项目同时使用两种主语言、标准排除句用词一时列不全),如实记录已确定的部分,允许后续 overview-init/业务初始化过程中发现遗漏再回来补一条,不强行一次性穷尽、不臆造。
- 本阶段执行者不预设专属角色(产品/架构/开发均可)——它是纯粹的事实盘点,不需要专业判断,和 `overview-init.md` 步 1(需要判断类专业分诊)性质不同。
- 体系版本升级后是否需要重新核对:凡本次升级改动了标准排除句模板结构、或 `overview-rules.md` 五节的发现方法/默认参考类目,建议重新核对一次 `DATA_PROJECT_FACTS`;凡只是措辞或文档结构调整,不强制重跑。

### 通过判据

`DATA_PROJECT_FACTS` 文件存在且六个字段(项目名 / 主语言运行时 / 标准排除句用词清单 / 代码位置 / 代码索引排除路径 / 完成日期)均非空,「代码位置」登记的每个路径都存在;`ENTRY_PATHS` 的 `MOUNT_ROOT` 行与本项目实际挂载位置一致。

### 引用的规则条款

- 路径表机制与例外(`ENTRY_PATHS` 本文件)
- 项目名取法(`GOVERNANCE_RULES` 的 `overview-rules.md` 一)
- 标准排除句的消费方式(`GOVERNANCE_FLOW_INIT` 的 `step1-overview.md`、`GOVERNANCE_FLOW_UPDATE` 的 `step3-extract.md`)
- 代码位置的消费方式(`GOVERNANCE_RULES` 的 `business-rule.md`「codegraph 查询口径」、`GOVERNANCE_PREPARE` 第二部分)
- 代码索引排除路径的消费方式(`GOVERNANCE_PREPARE` 第 3 步)
- 配件行判定方法(`GOVERNANCE_RULES` 的 `overview-rules.md` 四·4.2/4.3,本阶段不重复其判据,只作前置事实准备)
