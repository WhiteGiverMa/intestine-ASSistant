# Intestine ASSistant - 肠胃健康助手

一款帮助用户记录和分析排便数据的智能健康应用，通过AI分析提供个性化的肠胃健康建议。

## 功能特性

- **排便记录** - 记录时间、时长、粪便形态（布里斯托分类）、颜色、感受等
- **数据统计** - 可视化展示排便频率、时间分布、形态分布等（折线图、分布图、日历视图）
- **AI 分析与对话** - 基于记录数据提供健康评分和个性化建议，支持流式对话（需配置 DeepSeek API Key）
- **无排便标注** - 支持标注无排便日期，完善健康追踪
- **本地优先** - 所有数据本地存储，无需部署服务器
- **数据导入导出** - 支持 JSON 格式导出/导入，方便数据迁移
- **多主题切换** - 内置多套配色主题，明暗模式自由切换
- **响应式布局** - 自适应手机/平板/桌面宽屏，窄屏底栏 / 宽屏侧栏导航
- **系统提醒** - 支持定时提醒记录排便
- **版本更新检测** - 自动检查 GitHub Release 新版本

## 技术栈

| 层级 | 技术 |
|------|------|
| 前端 | Flutter (跨平台) |
| 数据库 | SQLite (本地存储) |
| AI | DeepSeek API (用户自备 API Key) |

## 项目结构

```
├── frontend_Flutter/           # Flutter 应用 (主项目，当前唯一活跃代码)
│   ├── lib/
│   │   ├── pages/              # 页面与功能编排 (含子级 AGENTS.md)
│   │   ├── widgets/            # 可复用 UI 组件 (含子级 AGENTS.md)
│   │   ├── services/           # 服务层：SQLite、AI、导出、更新 (含子级 AGENTS.md)
│   │   ├── providers/          # ThemeProvider、AuthProvider 状态管理
│   │   ├── theme/              # 颜色、装饰、样式装配
│   │   ├── models/             # 数据模型 (单文件 barrel)
│   │   └── utils/              # 响应式、动画、平台分流工具
│   ├── scripts/                # 辅助脚本 (图标生成、版本更新、安装)
│   ├── releases/               # 已构建的发布产物 (APK 等)
│   └── AGENTS.md               # Flutter 层知识库入口
├── AGENTS.md                   # 仓库级知识库 (AI 代理导航用)
├── .trae/rules/                # 编码规范、架构问题清单
├── docs/                       # 产品/技术需求文档
├── frontend_ReactWeb/          # 已弃用的 React 前端 (历史残留)
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

本项目由 **GLM**、**Kimi** 和 **DeepSeek** 全程生成代码，开发者仅进行产品设计指导和 Vibe Coding。

感谢这些优秀的 AI 模型让创意得以快速实现！
