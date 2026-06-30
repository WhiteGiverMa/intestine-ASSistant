# Intestine ASSistant - Flutter 前端

肠胃健康助手的主应用，Flutter 跨平台实现。当前唯一活跃维护的代码。

## 技术栈

| 层级 | 技术 |
|------|------|
| 框架 | Flutter (Dart) |
| 状态管理 | Provider + ChangeNotifier |
| 数据库 | SQLite (`sqflite`) |
| AI | DeepSeek API (用户自备 Key，支持流式) |
| 图表 | fl_chart |
| 平台 | Android / Web |

## 项目架构

```
lib/
├── main.dart              # 应用入口，MultiProvider 初始化
├── pages/                 # 页面层 (18 个文件，含 AGENTS.md)
│   ├── main_container.dart    # 主导航：4 Tab + 响应式布局切换
│   ├── home_page.dart         # 首页/记录入口
│   ├── data_overview_page.dart # 统计图表 + 日历 + 记录管理
│   ├── analysis_page.dart     # AI 分析/聊天 (最大热点 ~1800 行)
│   ├── settings_page.dart     # 设置总入口
│   └── ...
├── widgets/               # 可复用 UI 组件 (含 AGENTS.md)
│   ├── stats_charts.dart      # fl_chart 图表集合
│   ├── record_cards.dart      # 记录卡片/无排便卡片
│   ├── app_bottom_nav.dart    # 底部导航
│   └── ...
├── services/              # 服务层 (含 AGENTS.md)
│   ├── api_service.dart       # 页面统一入口 (Facade)
│   ├── local_db_service.dart  # SQLite Repository (~950 行)
│   ├── deepseek_service.dart  # DeepSeek 客户端
│   ├── database_service.dart  # SQLite 建库/迁移
│   └── ...
├── providers/             # ThemeProvider、AuthProvider
├── theme/                 # 颜色、装饰、主题装配
├── models/                # 数据模型 (单文件 barrel)
└── utils/                 # 响应式、动画、平台分流
```

> 详细架构说明见各级 `AGENTS.md`：根目录 → `frontend_Flutter/` → `lib/pages/` → `lib/widgets/` → `lib/services/`

## 快速开始

```bash
cd frontend_Flutter
flutter pub get

# Web 模式（推荐）
./start.ps1                    # 自动探测可用端口
# 或手动指定
flutter run -d chrome --web-port=5174

# Android
flutter run

# 静态分析
flutter analyze

# 格式化
dart format lib/
```

## 当前版本

**v1.3.6** (`pubspec.yaml`)

## 配置

应用无需后端服务。首次使用在设置页填入 DeepSeek API Key 即可启用 AI 分析功能。

所有数据和配置存储在本地 SQLite 数据库 (`settings` 表)，不使用 SharedPreferences。
