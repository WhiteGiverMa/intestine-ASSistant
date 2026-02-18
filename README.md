# Intestine ASSistant - 肠道健康助手

一款帮助用户记录和分析排便数据的智能健康应用，通过AI分析提供个性化的肠道健康建议。

## 功能特性

- **排便记录** - 记录时间、时长、粪便形态（布里斯托分类）、颜色、感受等
- **数据统计** - 可视化展示排便频率、时间分布、形态分布等
- **AI分析** - 基于记录数据提供健康评分和个性化建议
- **无排便标注** - 支持标注无排便日期，完善健康追踪

## 技术栈

| 层级 | 技术 |
|------|------|
| 前端 | Flutter (跨平台) |
| 后端 | FastAPI + SQLAlchemy |
| 数据库 | SQLite |
| AI | DeepSeek API |

## 项目结构

```
├── backend/           # FastAPI 后端服务
│   ├── app/
│   │   ├── routers/   # API 路由
│   │   ├── services/  # 业务逻辑
│   │   └── models.py  # 数据模型
│   └── requirements.txt
├── frontend_Flutter/  # Flutter 前端 (活跃开发)
└── frontend_ReactWeb/ # React Web 前端 (已弃用)
```

## 快速开始

### 后端

```bash
cd backend
pip install -r requirements.txt
python start.py
```

后端服务运行在 `http://localhost:8001`

### 前端

```bash
cd frontend_Flutter
flutter pub get
flutter run -d chrome --web-port=5174
```

## 分支说明

| 分支 | 内容 |
|------|------|
| `master` | 后端代码 |
| `frontend-flutter` | 完整项目（含 Flutter 前端） |
| `frontend-react-web` | 完整项目（含 React 前端，已弃用） |

## 特别声明

**本项目的代码遵循 MIT 协议开源，但以下内容保留所有权利：**

- 产品设计理念与创意
- 用户界面（UI）设计
- 交互设计方案
- 产品功能架构
- 文档中的产品设计描述

未经书面授权，不得将上述设计内容用于商业产品或进行直接复制。

## 致谢

本项目由 **GLM-5** 和 **DeepSeek V3.2** 全程生成代码，开发者仅进行产品设计指导和 Vibe Coding。

感谢这些优秀的 AI 模型让创意得以快速实现！

## License

本项目代码采用 [MIT License](LICENSE) 开源协议。
