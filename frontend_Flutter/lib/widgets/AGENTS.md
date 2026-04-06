# AGENTS.md

**位置**: `frontend_Flutter/lib/widgets/` — 可复用 UI 组件层

## OVERVIEW
这里放跨页面复用的导航、图表、卡片、输入和弹窗组件。很多页面体验问题最终都会落到这里修，而不是页面自身。

## STRUCTURE
```text
widgets/
├── app_bottom_nav.dart            # 底部导航，主 Tab 窄屏入口
├── app_header.dart                # 通用页头
├── base_page.dart                 # 页面壳层抽象
├── calendar_widget.dart           # 日历数据可视化
├── stats_charts.dart              # fl_chart 图表集合，大文件热点
├── record_cards.dart              # 记录卡片 / 无排便卡片，大文件热点
├── record_form_selectors.dart     # 记录表单选择器
├── date_input_field.dart          # 日期输入控件
├── compact_tab_switcher.dart      # 紧凑标签切换器
├── themed_switch.dart             # 主题化开关
├── error_dialog.dart              # 错误弹窗与内联错误
├── expanded_text_editor_dialog.dart # 文本编辑弹窗
├── export_options_dialog.dart     # 导出选项弹窗
├── analysis_result.dart           # AI 分析结果展示
└── top_feedback.dart / year_month_picker.dart ...
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| 主导航按钮表现 | `app_bottom_nav.dart` | `NavTab` 枚举和交互反馈在这里 |
| 统计图表 | `stats_charts.dart` | 基于 `fl_chart`，颜色来自 `ThemeColors` |
| 记录列表样式 | `record_cards.dart` | Bristol emoji、颜色标签、LID 复制交互 |
| 表单日期输入 | `date_input_field.dart`, `year_month_picker.dart` | 数据页/记录页常用 |
| 统一错误呈现 | `error_dialog.dart` | 弹窗与内联错误共用入口 |
| 文本/导出弹窗 | `expanded_text_editor_dialog.dart`, `export_options_dialog.dart` | 页面级弹窗组件 |
| 标签切换容器 | `compact_tab_switcher.dart` | 多页内部的小型 Tab 复用 |

## CONVENTIONS
- 视觉样式优先复用 `ThemeColors` 与 `ThemeDecorations`，不要在组件里散落新的硬编码样式体系。
- 数据展示组件通常接收模型对象或 `ThemeColors`，保持“页面组装数据，组件只负责显示”的边界。
- 交互细节已经有统一模式：轻量触感反馈、`Animated*` 微动效、`SnackBar`/弹窗错误提示。
- 图表组件依赖 `fl_chart`，改视觉时先确认坐标轴、tooltip 和空态行为是否一起需要更新。

## ANTI-PATTERNS
- 不要在通用组件里偷偷读取页面私有状态或服务层；这会让复用组件重新绑定到单页场景。
- 不要绕过 `ThemeColors` / `ThemeDecorations` 直接复制颜色和卡片样式。
- 不要把页面专用组件盲目下沉进来；若组件只被单一页面和局部流程使用，优先留在对应页面模块附近。
- 不要低估 `stats_charts.dart` 和 `record_cards.dart` 的修改面，这两个文件都已经进入大文件区间。

## HOTSPOTS
- `stats_charts.dart`：约 540+ 行，折线图/分布图等可视化逻辑集中。
- `record_cards.dart`：约 560+ 行，记录卡片、标签、复制、删除等交互都在这里。
- `compact_tab_switcher.dart`：多个页面共享的小型切换组件，改动会波及分析页/数据页等复用点。

## NOTES
- `app_bottom_nav.dart` 的 `NavTab` 是主导航枚举来源，导航相关改名要同步 `main_container.dart`。
- `error_dialog.dart` 不只是模态框，还提供内联错误组件，处理错误 UI 时别只改一个入口。
- 如果页面出现“只是样式问题”，先搜 widgets 再搜 pages，很多视觉逻辑已经被抽出来了。
