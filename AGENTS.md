# AGENTS.md

## 项目概述

Intestine ASSistant - 肠道健康助手，帮助用户记录和分析排便数据，通过AI分析提供个性化健康建议。

**技术栈**: Flutter + FastAPI + SQLite + DeepSeek API

## 关键目录

```
backend/              # FastAPI 后端服务
├── app/routers/      # API 路由
├── app/services/     # 业务逻辑
└── app/models.py     # 数据模型

frontend_Flutter/     # Flutter 前端 (活跃开发)
├── lib/pages/        # 页面组件
├── lib/services/     # API 服务
└── lib/widgets/      # 通用组件

frontend_ReactWeb/    # React Web 前端 (已弃用)
```

## 开发命令

```bash
# 后端
cd backend
pip install -r requirements.txt
python start.py

# 前端
cd frontend_Flutter
flutter pub get
flutter run -d chrome --web-port=5174
```

## 服务端口

| 服务 | 端口 | 状态 |
|------|------|------|
| 后端 API | http://localhost:8001/api/v1 | 活跃 |
| Flutter Web | http://localhost:5174 | 活跃 |
| React Web | http://localhost:5173 | 已弃用 |

## API 规范

### 认证
- 方式: JWT Bearer Token
- Header: `Authorization: Bearer {token}`

### 响应结构
- 登录/注册接口: 直接返回 `{ user_id, email, token }`，无 data 包装
- 其他接口: 包装在 `data` 字段中
- `time_distribution` 空数据返回 `{}`，需兼容处理

### 认证错误处理

检测到认证错误时：清token + 友好提示 + 引导登录

```javascript
// React
if (errorMsg.includes('认证') || errorMsg.includes('token')) {
  localStorage.removeItem('token')
  setError('登录已过期，请重新登录')
}
```

```dart
// Flutter
if (errorMsg.contains('认证') || errorMsg.contains('token')) {
  await prefs.remove('token');
  setState(() => _message = '登录已过期，请重新登录');
}
```

## 代码规范

- 注意修复尾随空格（Trailing whitespace），保持代码整洁
- 遵循现有代码风格和命名约定
- 显式优于隐式

## 代码检查

项目已配置 linter 和 formatter，修改代码后请运行检查：

```bash
# 后端 (Python) - 在 backend/ 目录下运行
ruff check app/          # 检查代码问题
ruff check app/ --fix    # 自动修复问题
ruff format app/         # 格式化代码

# 前端 (Flutter) - 在 frontend_Flutter/ 目录下运行
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
