# Intestine ASSistant - 肠胃健康助手

一款帮助用户记录和分析排便数据的智能健康应用，通过AI分析提供个性化的肠胃健康建议。

## 功能特性

- **排便记录** - 记录时间、时长、粪便形态（布里斯托分类）、颜色、感受等
- **数据统计** - 可视化展示排便频率、时间分布、形态分布等
- **AI分析** - 基于记录数据提供健康评分和个性化建议（需配置 DeepSeek API Key）
- **无排便标注** - 支持标注无排便日期，完善健康追踪
- **本地优先** - 所有数据本地存储，无需部署服务器
- **数据导出** - 支持 JSON 格式导出/导入，方便数据迁移

## 技术栈

| 层级 | 技术 |
|------|------|
| 前端 | Flutter (跨平台) |
| 数据库 | SQLite (本地存储) |
| AI | DeepSeek API (用户自备 API Key) |

## 项目结构

```
├── frontend_Flutter/     # Flutter 应用 (主项目)
│   ├── lib/pages/        # 页面组件
│   ├── lib/services/     # 服务层 (数据库、AI等)
│   └── lib/widgets/      # 通用组件
├── 产品需求文档.md
└── 技术需求文档.md
```

## 快速开始

```bash
cd frontend_Flutter
flutter pub get
flutter run -d chrome --web-port=5174
```

应用运行在 `http://localhost:5174`

## 分支说明

| 分支 | 内容 |
|------|------|
| `master` | 无后端版本 (当前主分支) |
| `frontend-flutter` | 前后端分离版本 (历史版本) |
| `frontend-react-web` | React 前端 (已弃用) |

## License

本项目采用 **GNU General Public License v3.0 (GPL v3)** 开源协议。

主要条款：
- ✅ 自由使用、研究、修改本软件
- ✅ 自由分发本软件及其修改版本
- ⚠️ 修改后的版本必须以相同协议开源
- ⚠️ 必须保留原作者版权声明
- ❌ 不得将本软件代码用于闭源商业产品

完整协议文本见 [LICENSE](./LICENSE) 文件。

## 致谢

本项目由 **GLM-5** 、**Kimi-K2.5**和 **DeepSeek V3.2** 全程生成代码，开发者仅进行产品设计指导和 Vibe Coding。

感谢这些优秀的 AI 模型让创意得以快速实现！
