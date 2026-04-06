---
alwaysApply: false
description:
---
# 编码指南

> 非关键性最佳实践，按需参考

## 修复流程

1. 修复当前问题
2. 更新 `project_rules.md` 记录规则
3. 检查并批量修复类似问题
4. 运行检查命令验证

## 代码质量

### 提交前检查
```bash
ruff check app/ --fix    # Python
flutter analyze          # Flutter
dart format lib/         # Flutter 格式化
```

### 用日志替代 print
```python
# ❌ 避免
print(f"调试: {data}")

# ✅ 推荐
import logging
logger = logging.getLogger(__name__)
logger.debug("调试: %s", data)
```

### 错误信息格式（推荐）
```json
{
  "error": {
    "message": "用户友好提示",
    "code": "ERROR_CODE",
    "action": "建议操作"
  }
}
```

## 检查命令
```bash
python .trae/rules/lint_patterns.py
```

## 修复记录
- 2026-04-07: 执行 init-deep，重写根级与 Flutter 应用 AGENTS.md，并新增 pages/widgets 子级知识库，纠正 services 文档中的旧结构描述
- 2025-02-21: 添加自动数据库迁移系统，解决 ai_auto_title 字段迁移问题
- 2025-02-24: 修复 TabController 回调在构建期间调用 setState 的问题，使用 `SchedulerBinding.instance.addPostFrameCallback` 延迟执行
- 2025-02-24: 修复 Duplicate GlobalKeys 问题，同一组件在多处使用时需使用不同的 GlobalKey
- 2025-02-24: 清理旧 token 认证机制遗留代码，项目已改为本地优先架构，API 配置存储在 SQLite 中，不再需要 SharedPreferences 存储 token/user
- 2025-02-25: 修复 `setState() called after dispose()` 错误，在所有异步操作后添加 `mounted` 检查，涉及 `chat_sidebar.dart` 和 `analysis_page.dart`
- 2025-02-25: 修复动画重复触发问题，`AnimationController` 初始值默认为 0.0，导致 `FadeTransition` 从 opacity 0 开始，初始化时需设置 `_controller.value = 1.0`
- 2025-02-25: 移除子页面淡入淡出动画，改用 `IndexedStack` 即时切换，只保留主页面滑动翻页动画
- 2025-02-25: 简化 `CompactTabBar` 和 `CompactTabContent`，移除 `TabController` 和 `AnimatedBuilder`，避免 `setState() during build` 错误
- 2025-02-25: 为子界面切换添加滑动翻页动画，与主界面动画逻辑一致
- 2025-02-25: 禁用 `AnimatedEntrance` 自动播放淡入动画，添加 `animate` 参数默认为 `false`，解决页面切换后内容重复淡入问题
- 2025-02-25: 同样修复 `AnimatedCard` 组件，添加 `animate` 参数默认为 `false`
- 2025-02-25: 修复设置页面开发者模式 Switch 动画问题，添加 `_initialized` 标志，等待异步加载完成后再渲染内容
- 2025-02-25: 修复快速点击导航导致界面不同步问题，动画进行中收到新切换请求时直接跳过动画跳转到目标页面
- 2025-02-25: 优化 AI 对话界面启动体验，默认显示新对话界面而非加载历史记录，避免渲染旧消息导致卡顿
- 2025-02-25: 移除消息气泡淡入动画，`AnimatedMessageBubble` 改为无状态组件直接返回 child
- 2025-02-25: AI 对话界面性能优化：将 `MarkdownStyleSheet` 创建提取为方法减少重复代码、缓存代码高亮解析结果避免重复计算、优化 `ThemeProvider` 访问减少子组件监听、缓存时间格式化结果

## 本地优先架构注意事项

### 认证机制
- 用户数据存储在 SQLite (`local_users` 表)
- API 配置存储在 SQLite (`settings` 表)
- 不再使用 SharedPreferences 存储 token/user
- `DeepSeekService.checkApiStatus()` 检查 API 配置状态

### 错误处理
- 本地优先模式下不会出现认证过期错误
- 错误处理时无需检查 `ErrorType.auth` 并清除 token
- 直接显示错误信息即可
