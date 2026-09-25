# 路径表(kb 体系唯一路径事实源)

> 体系内正文引用体系内文件/目录,一律用本表"逻辑名"指代,不直接写字面路径(例外见文末)。
> 改挂载位置只改 MOUNT_ROOT 一行;改内部目录结构只改本表对应行——不再需要全库排查旧写法。

## 挂载根

| 逻辑名 | 值 | 说明 |
|---|---|---|
| `MOUNT_ROOT` | `kb/`(相对项目仓库根) | 本体系当前挂载位置;换项目/换位置时只改这一行 |

## 目录 / 入口文件(下表路径均相对 MOUNT_ROOT)

| 逻辑名 | 实际相对路径 | 用途 | 类别 |
|---|---|---|---|
| `ENTRY_README` | `governance/README.md` | 人读入口 | 方法论 |
| `ENTRY_AGENTS` | `governance/AGENTS.md` | 治理契约入口 | 方法论 |
| `ENTRY_OVERVIEW` | `data/overview.md` | 项目现状索引 | 数据 |
| `ENTRY_PATHS` | `governance/PATHS.md` | 本表自身 | 方法论 |
| `GOVERNANCE_RULES` | `governance/rules/` | 规则与标准 | 方法论 |
| `GOVERNANCE_FLOW` | `governance/flow/` | 执行流程总目录 | 方法论 |
| `GOVERNANCE_FLOW_INIT` | `governance/flow/init/` | 业务初始化流程 | 方法论 |
| `GOVERNANCE_FLOW_UPDATE` | `governance/flow/update/` | 业务更新流程 | 方法论 |
| `GOVERNANCE_FLOW_SETUP` | `governance/flow/project-setup.md` | 项目适配初始化流程(一次性前置阶段) | 方法论 |
| `GOVERNANCE_PREPARE` | `governance/prepare.md` | 准备阶段:只装代码查询工具的命令行、建索引、就绪检查(不属于流程,走任何流程前做一次) | 方法论 |
| `GOVERNANCE_TOOL_SCAN` | `governance/scripts/tool-residue-scan.sh` | 只读扫描 codegraph/graphify 接入 Claude Code 的残留,输出为空即干净 | 方法论 |
| `GOVERNANCE_TOOL_SETUP` | `governance/tool-setup.md` | 代码查询工具(codegraph/graphify)的说明:各管什么、为什么不接进助手、查询前刷新 | 方法论 |
| `DATA_BUSINESS` | `data/business/` | 业务规则页(`type: rule`) | 数据 |
| `DATA_BUSINESS_RAW` | `data/business/raw/` | 业务取证批次原始产物 | 数据 |
| `DATA_CONTRACT_SURFACE` | `data/contract-surface.md` | 登记页·契约面(`type: registry`) | 数据 |
| `DATA_CONFIG_SURFACE` | `data/config-surface.md` | 登记页·配置面(`type: registry`) | 数据 |
| `DATA_ARCHITECTURE` | `data/architecture/` | 架构类数据(预留,启用需先修订 overview-rules 五节规则) | 数据 |
| `DATA_ARCHITECTURE_RAW` | `data/architecture/raw/` | 架构类取证批次原始产物(命名模式预留,当前无实际目录) | 数据 |
| `DATA_OVERVIEW_RAW` | `data/overview/raw/` | 全局概览初始化/重建流程步 1 盘点清单原始产物,按批次目录存放(见 `GOVERNANCE_FLOW` 的 `overview-init.md`) | 数据 |
| `DATA_IMAGES` | `data/images/` | 全部 SVG 图片 | 数据 |
| `DATA_LOG` | `data/log.md` | 变更史 | 数据 |
| `DATA_LESSONS` | `data/lessons.md` | 经验库 | 数据 |
| `DATA_PROJECT_FACTS` | `data/project-facts.md` | 项目适配事实卡(`GOVERNANCE_FLOW_SETUP` 前置阶段产出,记录本项目名称/主语言运行时/标准排除句用词/代码位置/代码索引排除路径等,供三条常规流程与规则文件引用取值,不需回头编辑规则文件本身) | 数据 |
| `DATA_OVERVIEW_EXCLUDE` | `data/overview-exclude.md` | 已核实的项目专属"未分类默认排除"例外记录(增量追加) | 数据 |

## 例外(不查表,直接写字面路径)

1. **真实 Markdown 超链接**(`[文字](路径)`,给人/Obsidian/GitHub 点击跳转的):必须写可解析的字面相对路径——渲染器不认识逻辑名,这是可用性硬约束。正确性由链接检查核对,不落入"治理文件不写字面路径"的范围。
2. **`data/log.md`、`data/lessons.md` 正文**(含历史条目与今后新增条目):记录具体历史事实,一律写字面路径,不抽象成逻辑名。
3. **`AGENTS.md` 声明本表位置的那一行**:有且只有一处字面路径(`governance/PATHS.md`),否则无从发现路径表本身。
