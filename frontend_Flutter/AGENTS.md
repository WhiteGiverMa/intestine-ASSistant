# AGENTS.md

**位置**: `frontend_Flutter/` — 当前维护中的 Flutter 应用根目录

## OVERVIEW
这里是项目的实际工作区。应用入口、页面编排、服务层、状态管理、主题系统和平台适配都集中在这个目录；仓库其余目录大多是文档、发布产物或历史残留。

## STRUCTURE
```text
lib/
├── main.dart                 # 应用入口，初始化 Theme/Auth Provider
├── models/models.dart        # 单一 barrel，集中定义所有 DTO/实体
├── pages/                    # 页面与功能编排（见 pages/AGENTS.md）
├── widgets/                  # 可复用 UI 组件（见 widgets/AGENTS.md）
├── services/                 # 数据访问与系统能力（见 services/AGENTS.md）
├── providers/                # 主题与本地用户状态
├── theme/                    # 颜色、装饰、样式、主题装配
└── utils/                    # 响应式、动画、平台分流工具

test/
├── widget_test.dart          # 当前唯一测试入口

scripts/
└── generate_icons.py         # 图标资源脚本
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| 启动流程 | `lib/main.dart` | `App` → `AppInitializer` → `MainContainer` |
| 主 Tab 与布局切换 | `lib/pages/main_container.dart` | `PageView` + 窄屏底栏/宽屏侧栏 |
| 数据模型 | `lib/models/models.dart` | 单文件 barrel，改动需注意连锁影响 |
| 页面功能 | `lib/pages/AGENTS.md` | 首页、数据、分析、设置及辅助页 |
| 通用组件 | `lib/widgets/AGENTS.md` | 图表、卡片、输入控件、导航组件 |
| 数据/AI/系统服务 | `lib/services/AGENTS.md` | SQLite、本地设置、AI 对话、更新检测 |
| 主题系统 | `lib/theme/*.dart` | `ThemeProvider` 驱动颜色和装饰 |
| 平台差异 | `lib/utils/file_download*.dart` | `io/web/unsupported` 三路实现 |

## CONVENTIONS
- 状态管理采用 `Provider + ChangeNotifier`，当前只有 `AuthProvider` 和 `ThemeProvider` 两个全局 provider。
- 配置读取优先走 `LocalDbService.getSetting()/setSetting()`，不是 SharedPreferences。
- 模型继续集中在 `lib/models/models.dart`；新增模型时要补齐 `fromJson` / `toJson`。
- 模块头注释格式已经在部分文件落地，新增或重构大文件时优先沿用：
  ```dart
  // @module: xxx
  // @type: service|provider|model|page|widget
  // @layer: frontend
  // @depends: [...]
  // @brief: ...
  ```
- 代码风格以 `analysis_options.yaml` 为准，仓库显式开启 `avoid_print`、`prefer_single_quotes`、`use_build_context_synchronously`。

## ANTI-PATTERNS
- 不要把新业务状态直接塞回页面私有状态，若跨页面复用明显，优先考虑 provider 或服务层抽离。
- 不要新增新的配置存储通道；现有“设置页 → SQLite settings 表”链路已经是项目约定。
- 不要继续放大 `models.dart`、`analysis_page.dart`、`local_db_service.dart` 这类热点文件而不记录影响。
- 不要在宽屏/窄屏导航上各写一套逻辑；主导航以 `main_container.dart` 为单一真相。

## COMMANDS
```bash
flutter pub get
./start.ps1
flutter run -d chrome --web-port=5174
flutter analyze
dart format lib/
flutter test
```

## NOTES
- `start.ps1` 会自动探测 5174 起的可用端口，优先用它启动 Web。
- `test/widget_test.dart` 覆盖很薄，做结构性改动时要额外依赖 `flutter analyze` 和人工验证。
- 当前推荐子级文档：`lib/pages/AGENTS.md`、`lib/widgets/AGENTS.md`、`lib/services/AGENTS.md`。
