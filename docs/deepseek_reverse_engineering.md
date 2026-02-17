# DeepSeek官网逆向工程方案

## 概述

本文档记录逆向工程DeepSeek官网免费AI对话的技术方案，用于在API调用失败时作为降级方案。

## 三级降级架构

```
用户请求分析
    ↓
┌─────────────────────────────────────┐
│ 第一级：DeepSeek API（付费）         │
│ - 官方API接口                        │
│ - 稳定可靠，有SLA保障                │
│ - 需要API密钥                        │
└─────────────────────────────────────┘
    ↓ 失败/无密钥
┌─────────────────────────────────────┐
│ 第二级：DeepSeek官网免费对话（逆向）  │
│ - 模拟网页请求                       │
│ - 免费但有限制                       │
│ - 需要维护登录状态                   │
└─────────────────────────────────────┘
    ↓ 失败/受限
┌─────────────────────────────────────┐
│ 第三级：本地规则分析                 │
│ - 纯算法分析                         │
│ - 无外部依赖                         │
│ - 基于规则的评分系统                 │
└─────────────────────────────────────┘
```

## 技术栈

| 技术领域 | 工具/库 | 用途 |
|----------|---------|------|
| 网页自动化 | Playwright / Selenium | 模拟浏览器操作 |
| HTTP请求 | httpx / requests | 发送API请求 |
| 逆向分析 | Chrome DevTools / Fiddler | 抓包分析请求格式 |
| 会话管理 | cookiejar / localStorage | 维护登录状态 |
| 流式响应 | SSE / WebSocket | 处理AI流式输出 |
| 反检测 | undetected-chromedriver | 绕过自动化检测 |

## 逆向工程步骤

### 步骤1：抓包分析

```
1. 打开 DeepSeek官网 (chat.deepseek.com)
2. F12 打开开发者工具 → Network面板
3. 发送一条对话消息
4. 分析请求：
   - 请求URL
   - 请求方法 (POST/GET)
   - 请求头 (Headers)
   - 请求体格式 (Body)
   - 响应格式 (JSON/SSE)
```

### 步骤2：识别关键请求

预期请求格式：
```
POST https://chat.deepseek.com/api/chat/completions
Headers:
  - Authorization: Bearer xxx (或Cookie认证)
  - Content-Type: application/json
  - X-Request-ID: xxx
  - Cookie: session_token=xxx

Body:
{
  "messages": [...],
  "model": "deepseek-chat",
  "stream": true
}
```

### 步骤3：认证方式分析

可能的认证方式：
- Cookie认证 - 从浏览器提取Cookie
- Bearer Token - 从localStorage/API获取
- 临时Token - 每次会话生成

## 实现方案对比

| 方案 | 优点 | 缺点 | 推荐度 |
|------|------|------|--------|
| 方案A：纯HTTP请求 | 快速、轻量 | 需要逆向认证机制 | ⭐⭐⭐⭐ |
| 方案B：Playwright自动化 | 模拟真实用户、绕过检测 | 资源消耗大、慢 | ⭐⭐⭐ |
| 方案C：混合方案 | 平衡性能和稳定性 | 实现复杂 | ⭐⭐⭐⭐⭐ |

## 代码框架

### 服务类设计

```python
# backend/app/services/deepseek_web_bridge.py

import httpx
import json
from typing import Optional, Dict, Any, List
from pathlib import Path

class DeepSeekWebBridge:
    """
    DeepSeek官网免费对话桥接服务
    
    实现三种方式的降级：
    1. 直接API调用（逆向出的接口）
    2. Playwright自动化
    3. 本地浏览器Cookie复用
    """
    
    def __init__(self):
        self.base_url = "https://chat.deepseek.com"
        self.session_token = None
        self.cookies = None
        self.cookie_file = Path("deepseek_cookies.json")
    
    async def initialize(self):
        """初始化，尝试加载保存的Cookie"""
        if self.cookie_file.exists():
            self.cookies = json.loads(self.cookie_file.read_text())
    
    async def chat_via_api(self, message: str, context: List[Dict] = None) -> Optional[str]:
        """
        方案1：直接调用逆向出的API
        
        需要先通过抓包分析确定：
        - API端点URL
        - 认证方式
        - 请求格式
        """
        if not self.cookies:
            return None
        
        try:
            async with httpx.AsyncClient(timeout=60.0) as client:
                # TODO: 根据抓包结果填写实际参数
                response = await client.post(
                    f"{self.base_url}/api/chat/completions",
                    headers={
                        "Content-Type": "application/json",
                        "Cookie": self._format_cookies(),
                        # 其他必要的请求头
                    },
                    json={
                        "messages": context or [{"role": "user", "content": message}],
                        "model": "deepseek-chat",
                        "stream": False
                    }
                )
                
                if response.status_code == 200:
                    return self._parse_response(response.json())
                return None
        except Exception as e:
            print(f"API调用失败: {e}")
            return None
    
    async def chat_via_browser(self, message: str) -> Optional[str]:
        """
        方案2：Playwright自动化
        
        启动无头浏览器，模拟用户操作
        """
        try:
            from playwright.async_api import async_playwright
            
            async with async_playwright() as p:
                browser = await p.chromium.launch(headless=True)
                context = await browser.new_context()
                
                # 加载保存的Cookie
                if self.cookies:
                    await context.add_cookies(self.cookies)
                
                page = await context.new_page()
                await page.goto(f"{self.base_url}/")
                
                # 等待页面加载
                await page.wait_for_selector("textarea", timeout=10000)
                
                # 输入消息
                await page.fill("textarea", message)
                
                # 点击发送按钮
                await page.click("button[type=submit]")
                
                # 等待响应
                await page.wait_for_selector(".response-content", timeout=30000)
                response_text = await page.text_content(".response-content")
                
                # 保存Cookie供下次使用
                self.cookies = await context.cookies()
                self._save_cookies()
                
                await browser.close()
                return response_text
                
        except Exception as e:
            print(f"浏览器自动化失败: {e}")
            return None
    
    async def get_cookies_from_browser(self) -> bool:
        """
        方案3：从本地浏览器提取Cookie
        
        支持Chrome/Edge浏览器
        """
        try:
            import browser_cookie3
            
            # 尝试从Chrome获取
            cookies = browser_cookie3.chrome(domain_name='deepseek.com')
            if cookies:
                self.cookies = {c.name: c.value for c in cookies}
                self._save_cookies()
                return True
            
            # 尝试从Edge获取
            cookies = browser_cookie3.edge(domain_name='deepseek.com')
            if cookies:
                self.cookies = {c.name: c.value for c in cookies}
                self._save_cookies()
                return True
                
        except Exception as e:
            print(f"获取浏览器Cookie失败: {e}")
        return False
    
    def _format_cookies(self) -> str:
        """格式化Cookie字符串"""
        if isinstance(self.cookies, dict):
            return "; ".join([f"{k}={v}" for k, v in self.cookies.items()])
        return ""
    
    def _save_cookies(self):
        """保存Cookie到文件"""
        self.cookie_file.write_text(json.dumps(self.cookies, ensure_ascii=False))
    
    def _parse_response(self, data: dict) -> str:
        """解析API响应"""
        # TODO: 根据实际响应格式调整
        if "choices" in data:
            return data["choices"][0]["message"]["content"]
        return data.get("content", "")


# 单例实例
deepseek_web_bridge = DeepSeekWebBridge()
```

### 集成到LLM服务

```python
# backend/app/services/llm_service.py 修改

from app.services.deepseek_web_bridge import deepseek_web_bridge

class LLMService:
    async def analyze_bowel_health(self, records_data, stats_data, analysis_type):
        # 第一级：尝试官方API
        if self.use_llm:
            result = await self._call_official_api(...)
            if result:
                return result, "deepseek_api"
        
        # 第二级：尝试官网逆向
        result = await self._call_web_bridge(...)
        if result:
            return result, "deepseek_web"
        
        # 第三级：本地分析（由调用方处理）
        return None
```

## 依赖安装

```txt
# requirements.txt 新增
playwright==1.40.0
browser-cookie3==0.19.1
sseclient-py==1.8.0
websockets==12.0
```

安装Playwright浏览器：
```bash
playwright install chromium
```

## 风险与限制

| 风险 | 说明 | 应对策略 |
|------|------|----------|
| 账号封禁 | 频繁自动化请求可能触发风控 | 控制请求频率、模拟人类行为 |
| 接口变更 | 官网可能随时修改API | 模块化设计、快速适配 |
| 登录过期 | Cookie/Token有时效性 | 定期刷新、自动重新登录 |
| 验证码 | 可能出现人机验证 | 集成验证码识别服务 |
| 法律风险 | 可能违反服务条款 | 仅个人学习使用 |

## 实施计划

1. **阶段1：抓包分析**
   - 使用Chrome DevTools分析DeepSeek官网
   - 确定API端点和认证方式
   - 记录请求/响应格式

2. **阶段2：实现基础功能**
   - 实现Cookie提取
   - 实现基础API调用
   - 测试连接稳定性

3. **阶段3：完善降级机制**
   - 集成Playwright自动化
   - 实现Cookie持久化
   - 添加错误处理

4. **阶段4：优化与测试**
   - 性能优化
   - 异常处理完善
   - 集成测试

## 参考资料

- [Playwright文档](https://playwright.dev/python/)
- [browser-cookie3](https://github.com/borisbabic/browser_cookie3)
- [SSE (Server-Sent Events)](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events)
- [DeepSeek官网](https://chat.deepseek.com/)

## 更新日志

- 2026-02-17: 初始方案设计
