# AGENTS.md

**位置**: `frontend_Flutter/lib/services/` — 本地数据、AI、系统能力服务层

## OVERVIEW
这里封装 SQLite、设置存储、AI 对话/分析、提醒、版本检测和外链打开能力。UI 层默认不应直接越过这里去碰底层实现细节。

## FILE MAP
| 文件 | 角色 | 当前特点 |
|------|------|----------|
| `database_service.dart` | SQLite 单例 | 建库、迁移、表结构真相来源 |
| `local_db_service.dart` | Repository / 静态入口 | 本地用户、记录、统计、聊天、设置、导入导出，全都在这里 |
| `deepseek_service.dart` | AI 客户端 | DeepSeek 配置、连接测试、聊天、分析 |
| `api_service.dart` | Facade | 给页面层提供统一本地/远程接口 |
| `timer_notification_service.dart` | 系统提醒 | 本地提醒调度 |
| `update_check_service.dart` | 版本检测 | 检查新版本与预发布状态 |
| `url_launcher_service.dart` | 外链服务 | 打开外部链接或商店/下载地址 |

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| 数据库 schema / 迁移 | `database_service.dart` | `settings`、`bowel_records`、`chat_*` 等表定义在这里 |
| CRUD / 统计 / 配置 | `local_db_service.dart` | 最大热点文件，改动前先搜同类方法 |
| AI 设置与请求 | `deepseek_service.dart` | API key、model、system prompt、streaming |
| 页面调用入口 | `api_service.dart` | 页面应尽量依赖这里而非多个底层服务 |
| 版本更新 UI 数据源 | `update_check_service.dart` | `settings_page.dart` 会消费它 |

## CONVENTIONS
- 本地优先：用户、记录、聊天、设置都落 SQLite；配置项统一经 `LocalDbService.getSetting()/setSetting()` 存取。
- `database_service.dart` 的 `_onUpgrade` 是迁移唯一入口；SQLite 不支持直接删列，迁移设计要保守。
- `ApiService` 是页面层首选入口，只有非常底层的设置/初始化场景才直接碰 `LocalDbService` 或 `DeepSeekService`。
- DeepSeek 配置（`api_key`、`api_url`、`model`、`system_prompt` 等）已约定保存在 `settings` 表。
- 异步调用返回 `Future`/`Stream`，页面层在 `await` 后必须保留 `mounted` 防线。

## ANTI-PATTERNS
- 不要新增一个“第二套设置存储”；SharedPreferences 在当前架构里是历史路径。
- 不要在页面里复制 SQL/统计逻辑；现有仓库约定是把这些逻辑集中在 `local_db_service.dart`。
- 不要把 `api_service.dart` 继续演化成巨型上帝类而不拆分关注点；它已经是服务层热点之一。
- 不要假设这里有独立 `error_handler.dart`；当前服务目录里没有这个文件，更新文档或调用链时别再写旧路径。

## KNOWN HOTSPOTS
- `local_db_service.dart` 约 950+ 行：用户、记录、统计、聊天、导入导出全堆在一起。
- `api_service.dart` 约 540+ 行：同时承担本地 facade 和 AI 上下文拼装。
- 服务层缺少配套单元测试；结构性改动后更依赖 `flutter analyze` 和页面级回归。

## DEPENDENCY SHAPE
```text
pages/widgets
  ↓
ApiService
  ├── LocalDbService
  │   └── DatabaseService
  ├── DeepSeekService
  ├── UpdateCheckService
  └── UrlLauncherService / TimerNotificationService
```
