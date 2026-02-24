# AGENTS.md

## 项目概述

Intestine ASSistant - 肠道健康助手，帮助用户记录和分析排便数据，通过AI分析提供个性化健康建议。

**架构**: 本地优先 (Local-First)，无需后端服务器

**技术栈**: Flutter + SQLite + DeepSeek API

## 关键目录

```
frontend_Flutter/     # Flutter 应用 (主项目)
├── lib/pages/        # 页面组件
├── lib/services/     # 服务层
│   ├── database_service.dart    # SQLite 数据库初始化
│   ├── local_db_service.dart    # 本地数据 CRUD 操作
│   ├── deepseek_service.dart    # DeepSeek API 调用
│   └── api_service.dart         # 统一 API 接口
├── lib/providers/    # 状态管理
├── lib/widgets/      # 通用组件
└── lib/theme/        # 主题配置
```

## 开发命令

### 推荐方式 (自动检测可用端口)
```powershell
cd frontend_Flutter
.\start.ps1          # PowerShell 脚本
# 或双击 start.bat   # 批处理文件
```

### 手动方式
```bash
cd frontend_Flutter
flutter pub get
flutter run -d chrome --web-port=5174
```

## 服务端口

| 服务 | 端口 | 说明 |
|------|------|------|
| Flutter Web | http://localhost:5174+ | 自动检测可用端口 |

## 本地数据架构

### 数据库 (SQLite)
- 位置: 应用沙盒目录 `intestine_assistant.db`
- 表: `local_users`, `bowel_records`, `chat_sessions`, `chat_messages`, `settings`

### 用户模式
- 本地用户，无需注册登录
- 首次启动自动创建本地用户

### AI 功能
- 用户在设置页面配置 DeepSeek API Key
- API Key 本地存储，不上传服务器
- 仅 AI 分析功能需要网络连接

## 代码规范

- 注意修复尾随空格（Trailing whitespace），保持代码整洁
- 遵循现有代码风格和命名约定
- 显式优于隐式
- 修复问题后，**简要**记录到 `.trae/rules/coding_guidelines.md` 的修复记录中

## 代码检查

```bash
cd frontend_Flutter
flutter analyze          # 检查代码问题
dart format lib/         # 格式化代码
```

**建议**: 在提交代码前运行检查，确保没有明显的代码质量问题。

## 架构文档

定位模块或发现架构问题时，主动查阅和更新：
- `.trae/rules/architecture_index.md` - 项目架构索引
- `.trae/rules/architecture_issues.md` - 架构问题清单

## 详细文档

根据任务需要，查阅以下文档：
- 产品需求: `产品需求文档.md`
- 技术架构: `技术需求文档.md`
- 项目说明: `README.md`
