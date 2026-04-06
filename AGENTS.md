# PROJECT KNOWLEDGE BASE

**Generated:** 2026-04-07
**Commit:** `8d956d4`
**Branch:** `master`

## OVERVIEW
Intestine ASSistant 是一个本地优先的肠胃健康记录应用。当前活跃代码几乎全部位于 `frontend_Flutter/`，使用 Flutter + SQLite + DeepSeek API；仓库内没有正在使用的后端服务。

## STRUCTURE
```text
Intestine-ASSistant/
├── frontend_Flutter/      # 当前维护中的 Flutter 应用
│   ├── lib/pages/         # 页面与功能编排（已拆出子级 AGENTS）
│   ├── lib/widgets/       # 可复用 UI 组件（已拆出子级 AGENTS）
│   └── lib/services/      # 数据库、AI、导出/更新等服务层
├── .trae/rules/           # 编码规范、架构索引、问题清单
├── docs/                  # 零散项目文档
├── frontend_ReactWeb/     # 已弃用，仅保留历史残留
└── README.md / 产品需求文档.md / 技术需求文档.md
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| 应用入口与初始化 | `frontend_Flutter/lib/main.dart` | `MultiProvider` 初始化主题与本地用户 |
| 主导航结构 | `frontend_Flutter/lib/pages/main_container.dart` | 4 个主 Tab，窄屏底栏/宽屏侧栏 |
| 页面功能分层 | `frontend_Flutter/lib/pages/AGENTS.md` | 数据、分析、设置、开发工具入口 |
| 通用组件选型 | `frontend_Flutter/lib/widgets/AGENTS.md` | 导航、图表、表单、弹窗组件 |
| 服务/数据层 | `frontend_Flutter/lib/services/AGENTS.md` | SQLite、本地设置、AI、更新、URL 打开 |
| 项目规则 | `.trae/rules/coding_guidelines.md` | 修复后需简要追加记录 |
| 架构风险/历史债务 | `.trae/rules/architecture_issues.md` | 大文件、缺少模块头等问题清单 |

## CONVENTIONS
- 以 `frontend_Flutter/` 为唯一活跃应用根目录；其它目录默认不作为实现目标，除非任务明确要求。
- 本地优先：除 AI 功能外，核心记录、统计、设置均依赖本地 SQLite，不依赖后端。
- 配置统一走 SQLite `settings` 表；不要把新配置继续落到 SharedPreferences。
- 修复完成后，要在 `.trae/rules/coding_guidelines.md` 的“修复记录”中追加一条简短说明。
- Flutter 代码受 `frontend_Flutter/analysis_options.yaml` 约束，重点包括 `prefer_single_quotes`、`avoid_print`、`use_build_context_synchronously`。

## ANTI-PATTERNS (THIS PROJECT)
- 不要把 `frontend_ReactWeb/` 误判为当前前端；它现在只是废弃残留。
- 不要依赖 `.trae/rules/architecture_index.md` 中旧的 backend 描述来做现状判断；该文件带有历史内容，当前实现以 Flutter 目录为准。
- 不要新增绕过服务层的本地存储方案；现有数据与配置都以 `LocalDbService`/SQLite 为中心。
- 不要忽略仓库里已经标出的超大文件问题，尤其是 `lib/pages` 与 `lib/services` 的热点文件。

## UNIQUE STYLES
- 根文档负责“仓库导航”，具体 Flutter 细节下沉到 `frontend_Flutter/` 及其子级 AGENTS。
- 文档需要优先描述“哪里改、别碰哪里”，而不是泛化的 Flutter 教程。
- 仓库里已提交发布产物（`frontend_Flutter/releases/`）；处理 Git 变更时要避免误操作这些二进制文件。

## COMMANDS
```bash
cd frontend_Flutter
./start.ps1                 # 推荐：自动探测可用端口运行 Flutter Web
flutter pub get
flutter run -d chrome --web-port=5174
flutter analyze
dart format lib/
flutter test
```

## NOTES
- 当前分支为 `master`，也是仓库 README 中标记的本地优先主分支。
- `frontend_Flutter/scripts/generate_icons.py`、`update_version.ps1`、`install_keep_data.ps1` 都是辅助脚本，不是日常入口。
- 现有 AGENTS 层级：`frontend_Flutter/`、`frontend_Flutter/lib/pages/`、`frontend_Flutter/lib/widgets/`、`frontend_Flutter/lib/services/`。
