# Flutter developer skill 抽离

日期：2026-11-23。范围：从项目 developer 提示词提炼通用 Flutter 开发能力。

已完成：个人目录 ~/.codex/skills/flutter-developer 下创建 SKILL.md、agents/openai.yaml 以及架构接入、设计缺口、协作回归、UGC 四份参考。项目 .codex/agents/developer.toml 改为技能入口，保留微撩 Figma 和设备验证分工。已有 flutter-feature-development 保留作为可选详细实现规范。没有修改业务代码。

决策：通用 skill 不固定产品领域、状态框架、模块名或设计文件；tester 和治理流程按需使用。

验证：Python tomllib 检查 agent 配置通过。官方 quick_validate.py 因缺少 yaml（PyYAML）未能运行。未运行 Flutter 测试和构建。

未完成/未验证：用户提供的 https://github.com/ZengJo/flutter_app_framework.git 网络读取失败，克隆未取得结果，未核实框架 API；新会话发现技能和真实项目行为未验证。

下一步：具备 PyYAML 后运行 quick_validate.py ~/.codex/skills/flutter-developer；提供可访问框架或本地路径后按 references/framework.md 核实架构，并执行实际业务任务验证。

## 后续：Paperclip 真实接口版本

日期：2026-11-23。用户要求独立生成真实业务开发 skill，不在当前 agent 安装。

已完成：交付 `/tmp/paperclip-skill-delivery/flutter-api-developer.zip`，入口 SKILL.md 与四份按需参考（framework、backend-integration、design-gaps、collaboration）。保留分层、组件复用、设计还原及协作理念；数据流程替换为真实接口契约、鉴权、状态映射、幂等、联调。去掉本地技能依赖与宿主专属工具要求。未修改旧 skill 或当前 agent。

对前述模板读取状态的后续更正：上轮克隆现已完成，本次实际读取模板 commit 96452f21a2d8dcb20d465a9d6eb9f72e22424ae7 的 README、request/HttpClient/请求头/拦截器及 Riverpod 示例。将取消与 401 返回 null、默认离线入队等真实接口接入注意事项纳入 framework.md；仅静态阅读，未运行框架。

验证：临时 venv 安装 PyYAML 后执行 skill-creator/scripts/quick_validate.py /tmp/paperclip-skill-delivery/flutter-api-developer，结果 Skill is valid!；相对参考链接、无本机绝对路径及 ZIP 完整性检查通过。未执行 Flutter 构建、后端联调或 Paperclip 加载测试。

剩余与下一步：用户将 ZIP 解压至实际 Paperclip agent 可读的 skill 位置，并在其提示词指向 SKILL.md；具体安装位置遵循实际部署配置。使用真实项目契约及测试环境验证首次任务。临时交付文件需另行保存，不作为长期仓库证据。

## 后续：完整前端与自主验收版本

日期：2026-11-23。范围：按用户四项要求调整 Paperclip 技能，名称改为 flutter-frontend-developer，保留上版交付以便追溯。

已完成：无项目时明确从指定 flutter_app_framework 仓库获取并初始化；规定模块职责及 enum/model/request-model/server 或 repository、presentation 文件分类，架构不符合时不能标模块完成；覆盖完整前端页面、交互、组件、状态、适配和真实后端接入；改为开发 agent 自行检查、修复、验收并直接报告用户，不依赖 tester 或其他 agent。新包使用 self-verification.md，未携带旧 collaboration.md。

交付：/tmp/paperclip-skill-delivery/flutter-frontend-developer.zip；同名目录包含 SKILL.md 与四份参考。未安装到当前项目或修改原有 agent/个人 skill。

验证：临时 venv 执行 skill-creator quick_validate.py，结果 Skill is valid!；相对文件引用、可移植路径和 ZIP 完整性检查通过。未运行实际 Flutter 项目任务、构建或 Paperclip 加载。

未完成/未验证及下一步：保存临时交付包到 Paperclip 实际技能位置，将开发 agent 入口更新为 flutter-frontend-developer/SKILL.md，使用真实前端需求验证初始化、分类及自主验收行为。

## 后续：Figma 原稿参数与还原核对

日期：2026-11-23。范围：补充用户指定的 Figma MCP / Figwright 读取及还原要求。

已完成：更新 flutter-frontend-developer 的 SKILL.md、references/design-gaps.md、references/self-verification.md，并重新打包同路径 ZIP。提供 Figma UI 时须读取原稿节点参数、截图、资源，确认文件连接；覆盖布局、字体、颜色、效果及组件变体，映射到现有组件，并由 agent 自行对照运行截图、整改复验。工具受限或缺截图证据时明确标注未验证。

验证：quick_validate.py 返回 Skill is valid!；相对引用和 ZIP 完整性通过。未实际调用 Figma/ Figwright，也未执行设备视觉验收，本次仅修改技能规则。

下一步：将更新后的交付包保存到 Paperclip，并在提供 Figma 的真实开发任务中验证读取及视觉核对流程。

## 后续：对照 developer 补齐编码细则

日期：2026-11-23。范围：用户反馈生成代码缺少注释，要求参考当前 developer 排查遗漏。

来源：当前 .codex/agents/developer.toml 是技能入口，详细实现规范位于 ~/.codex/skills/flutter-feature-development/SKILL.md；对照本次实际读取内容进行补充。

已完成：在交付包新增 references/code-conventions.md，并由 SKILL.md 要求编码前读取。补齐类/业务方法/局部构建方法的 /// 注释、布局分区与非直观分支 // 注释、字段含义单位和同步维护；新增自主验收项，缺失必要注释不得标记完成。

其他补齐差异：公共能力复用清单与实际接入检查；Widget/State 组织、Stateful 默认约定及基类适配；View 副作用与状态层边界、嵌套不可变更新和局部监听；presentation/model、enum、state、constant 分类；命名与回调规范；资源整套状态、注册及生成引用；枚举稳定编码和分页基类序列化；设计目标子树至叶子及逐节点组件归属。

有意保留差异：真实后端取代 Mock；agent 自主验收取代 tester 交接和默认由用户设备验收；不引入微撩专属业务、Figma 地址或社交治理全局要求。未改当前项目业务代码或个人已安装 skill。

验证：quick_validate.py 通过，文件引用与 ZIP 完整性通过；交付包 /tmp/paperclip-skill-delivery/flutter-frontend-developer.zip 共 6 个 Markdown 文件。未执行新 skill 的真实代码生成行为测试。

下一步：更新 Paperclip 技能目录并在下一次开发任务检查生成代码与自验记录，确认注释和分类要求实际执行。
