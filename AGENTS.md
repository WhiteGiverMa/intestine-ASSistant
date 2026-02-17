# AGENTS.md

## 认证错误处理

检测到认证错误时：清token + 友好提示 + 引导登录

// React
if (errorMsg.includes('认证') || errorMsg.includes('token')) {
  localStorage.removeItem('token')
  setError('登录已过期，请重新登录')
}
// Flutter
if (errorMsg.contains('认证') || errorMsg.contains('token')) {
  await prefs.remove('token');
  setState(() => _message = '登录已过期，请重新登录');
}
API端口:
统一使用 http://localhost:8001/api/v1

响应结构:
 - 登录/注册接口：直接返回 { user_id, email, token }，无 data 包装
 - 其他接口：包装在data字段中
 - time_distribution空数据返回 {}，需兼容处理
## 前端端口
frontend_ReactWeb: 5173（已弃用）
frontend_Flutter: 5174