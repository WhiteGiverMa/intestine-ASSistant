# AGENTS.md

**位置**: `frontend_Flutter/lib/pages/` — 页面层与功能编排层

## OVERVIEW
这里承担页面级状态、导航分发和跨组件组合。这个目录文件多、体量大，是当前 Flutter 应用最需要先定位再下刀的区域。

## STRUCTURE
```text
pages/
├── main_container.dart         # 主导航容器，4 个 Tab 的单一真相
├── home_page.dart              # 首页 / 记录入口
├── data_page.dart              # 数据页壳层
├── data_overview_page.dart     # 统计图表 + 日历 + 记录管理热点文件
├── analysis_page.dart          # AI 分析 / 聊天主页面，最大热点
├── chat_sidebar.dart           # 会话列表侧栏
├── chat_settings.dart          # 聊天设置面板
├── chat_message_widgets.dart   # 聊天气泡与流式渲染组件（仍放在 pages）
├── settings_page.dart          # 设置总入口
├── ai_chat_options_page.dart   # AI 参数设置热点文件
├── user_account_page.dart      # 本地用户信息热点文件
├── theme_selector_page.dart    # 主题选择
├── misc_settings_page.dart     # 其他设置
├── dev_tools_page.dart         # 开发辅助页
├── test_data_generator_page.dart # 测试数据生成热点文件
└── about_page.dart / splash_page.dart / record_page.dart ...
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| 主 Tab 切换 / 宽窄屏导航 | `main_container.dart` | `PageView` + `AppBottomNav` + `NavigationRail` |
| AI 分析或聊天体验 | `analysis_page.dart` | 含 AI 状态、流式响应、对话缓存、侧栏联动 |
| 数据总览 / 图表 / 日历联动 | `data_overview_page.dart` | 同时调统计、记录、日期筛选 |
| 设置首页与子页入口 | `settings_page.dart` | 主题、AI、用户、开发者模式、关于页 |
| 记录录入与编辑 | `record_page.dart` | 记录表单与保存链路 |
| 聊天气泡/消息 UI | `chat_message_widgets.dart` | 虽然名字像 widget，实际与分析页强绑定 |
| 开发测试入口 | `dev_tools_page.dart`, `test_data_generator_page.dart` | 仅开发模式可见或使用 |

## CONVENTIONS
- 页面层默认通过 `ApiService` / `LocalDbService` / provider 取数，不直接处理底层数据库细节。
- 主导航以 `main_container.dart` 为单一真相；首页、数据、分析、设置四个一级入口都从这里接入。
- 多个页面使用 `AutomaticKeepAliveClientMixin` 保持 Tab 状态，改生命周期逻辑时先确认缓存预期。
- 页面内部广泛依赖 `ThemeProvider`、`ThemeDecorations`、`ResponsiveUtils` 和 `AnimatedEntrance` 统一视觉行为。
- 这个目录已经部分采用模块头注释；新增大型页面时建议补齐同格式元信息。

## ANTI-PATTERNS
- 不要在页面间复制加载/错误/刷新逻辑；先搜索相邻页面是否已有现成模式。
- 不要忽略 `mounted` 检查；这里大量页面在异步加载后 `setState`。
- 不要把更多展示组件继续塞进 `analysis_page.dart`、`data_overview_page.dart`、`settings_page.dart`、`test_data_generator_page.dart` 这类热点文件里。
- 不要因为文件名里有 `widgets` 就把 `chat_message_widgets.dart` 当成通用组件目录的一部分；它更像分析页的局部子模块。

## HOTSPOTS
- `analysis_page.dart`：约 1800 行，AI 状态、聊天、流式响应、缓存、侧栏全部汇总。
- `test_data_generator_page.dart`：约 1100+ 行，开发辅助逻辑集中。
- `data_overview_page.dart`：约 1000+ 行，统计与记录管理强耦合。
- `record_page.dart` / `settings_page.dart` / `user_account_page.dart` / `ai_chat_options_page.dart`：均已过 500 行级别。

## NOTES
- 页面目录不只是“页面”；还混有 `chat_message_widgets.dart` 这类局部组件文件，改目录结构前先看调用面。
- 若任务只影响分析页聊天 UI，通常需要同时读 `analysis_page.dart`、`chat_sidebar.dart`、`chat_message_widgets.dart`、`chat_settings.dart`。
- 若任务只影响数据总览，通常至少要同时看 `data_overview_page.dart` 与 `lib/widgets/{calendar_widget,stats_charts,record_cards}.dart`。
