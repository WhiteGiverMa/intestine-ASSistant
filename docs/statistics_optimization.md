# 统计分析优化方案

## 问题背景

当前系统在进行周分析/月分析时，存在以下问题：

**场景举例：**
用户只记录了最近4天的数据（共5条记录）

- **周分析时**：`days = 7`（固定），`avg_frequency = 5/7 = 0.71次/天` → 被判定为"频率偏低"
- **月分析时**：`days = 30`（固定），`avg_frequency = 5/30 = 0.17次/天` → 触发"排便频率过低"警告

**根本原因：** 系统将"未记录"等同于"未排便"，导致统计结果不准确。

---

## 混合优化方案

### 一、统计数据增强

#### 1.1 新增统计字段

```python
{
    "total_records": 5,           # 总记录数
    "days": 7,                    # 分析周期天数
    "recorded_days": 4,           # 实际记录天数（新增）
    "coverage_rate": 0.57,        # 数据覆盖率（新增）
    "avg_frequency": 1.25,        # 基于实际记录天数计算（修改）
    "avg_duration": 8.5,          # 平均排便时长
    "type_dist": {...},           # 粪便类型分布
    "feeling_dist": {...},        # 排便感受分布
    "time_dist": {...}            # 时间段分布
}
```

#### 1.2 计算逻辑修改

```python
def calculate_stats(records, start_date, end_date) -> dict:
    total_records = len(records)

    # 计算实际记录天数
    recorded_dates = set(r.record_date for r in records)
    recorded_days = len(recorded_dates)

    # 计算分析周期天数
    period_days = (end_date - start_date).days or 1

    # 数据覆盖率
    coverage_rate = recorded_days / period_days if period_days > 0 else 0

    # 平均频率：基于实际记录天数
    avg_frequency = round(total_records / recorded_days, 2) if recorded_days > 0 else 0

    return {
        "total_records": total_records,
        "days": period_days,
        "recorded_days": recorded_days,
        "coverage_rate": round(coverage_rate, 2),
        "avg_frequency": avg_frequency,
        # ... 其他字段
    }
```

---

### 二、"无排便"标注功能

#### 2.1 数据模型

在 `BowelRecord` 模型中增加 `is_no_bowel` 字段：

```python
class BowelRecord(Base):
    __tablename__ = "bowel_records"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    record_date = Column(String(10))
    record_time = Column(String(5))

    # 新增：标记当天无排便
    is_no_bowel = Column(Boolean, default=False)

    # 原有字段...
    duration_minutes = Column(Integer)
    stool_type = Column(Integer)
    # ...
```

#### 2.2 API接口

```python
# POST /records/no-bowel
# 标注某天无排便
{
    "date": "2025-02-15"
}

# DELETE /records/no-bowel/{date}
# 取消无排便标注
```

---

### 三、AI分析Prompt优化

#### 3.1 System Prompt 增强

```
注意：
1. health_score 基于排便频率、时长、粪便形态、感受等综合评估
2. insights 应包含2-4条有价值的洞察
3. suggestions 应包含2-3条实用的改善建议
4. warnings 仅在发现明显健康问题时添加
5. 请用中文回复
6. 【重要】如果数据覆盖率低于50%，请在分析中说明"数据较少，分析结果仅供参考"
```

#### 3.2 User Prompt 增强

```python
prompt = f"""请分析以下{period}的排便记录数据：

## 数据说明
- 分析周期: {stats_data.get('days', 0)}天
- 实际记录: {stats_data.get('recorded_days', 0)}天 (覆盖率{stats_data.get('coverage_rate', 0)*100:.0f}%)
- 注意: {'用户可能存在未记录的天数，请谨慎分析' if stats_data.get('coverage_rate', 0) < 0.8 else '数据较为完整'}

## 统计概览
- 记录总数: {stats_data.get('total_records', 0)}条
- 平均排便频率: {stats_data.get('avg_frequency', 0)}次/天（基于实际记录天数）
...
"""
```

---

### 四、前端日历组件

#### 4.1 日历UI设计

```
┌─────────────────────────────────────┐
│           2025年2月                  │
├─────────────────────────────────────┤
│  日   一   二   三   四   五   六    │
├─────────────────────────────────────┤
│      1    2    3    4    5    6    7│
│          2次       0               1次│
├─────────────────────────────────────┤
│  8    9   10   11   12   13   14   │
│  1次            1次                 │
├─────────────────────────────────────┤
│ 15   16   17   18   19   20   21   │
│  0                                  │
└─────────────────────────────────────┘

图例：
- 数字下方显示排便次数
- "0" 表示用户标注无排便
- 无数字表示未记录
```

#### 4.2 交互设计

1. **选择单日**：显示该日的所有排便记录
2. **选择日期范围**：显示该范围内的所有记录
3. **长按/右键无记录日期**：弹出菜单，选择"标注无排便"
4. **点击已标注日期**：可取消"无排便"标注

---

### 五、覆盖率提示策略

| 覆盖率 | 提示信息 | 分析可靠性 |
|--------|----------|------------|
| < 30% | "数据严重不足，建议持续记录后再分析" | 不可靠 |
| 30%-50% | "数据较少，分析结果仅供参考" | 较低 |
| 50%-80% | "分析结果仅供参考" | 中等 |
| > 80% | 正常展示 | 较高 |

---

### 六、影响范围

| 模块 | 文件 | 修改内容 |
|------|------|----------|
| 后端数据模型 | `backend/app/models.py` | 添加 `is_no_bowel` 字段 |
| 后端记录API | `backend/app/routers/records.py` | 添加无排便标注接口 |
| 后端统计API | `backend/app/routers/stats.py` | 增加 `recorded_days`、`coverage_rate` |
| 后端AI分析 | `backend/app/routers/ai.py` | 修改统计计算逻辑 |
| 后端LLM服务 | `backend/app/services/llm_service.py` | 优化Prompt |
| 前端日历组件 | `frontend_Flutter/lib/widgets/calendar_widget.dart` | 新建日历组件 |
| 前端数据管理 | `frontend_Flutter/lib/pages/data_management_page.dart` | 集成日历、支持无排便标注 |
| 前端API服务 | `frontend_Flutter/lib/services/api_service.dart` | 添加无排便标注API |

---

### 七、数据库迁移

```sql
-- 添加 is_no_bowel 字段
ALTER TABLE bowel_records ADD COLUMN is_no_bowel BOOLEAN DEFAULT 0;

-- 创建索引优化查询
CREATE INDEX idx_bowel_records_user_date ON bowel_records(user_id, record_date);
```

---

### 八、预期效果

1. **统计更准确**：基于实际记录天数计算频率
2. **用户更明确**：清楚了解数据完整度
3. **分析更智能**：AI能考虑数据覆盖率
4. **交互更友好**：日历直观展示记录情况
5. **数据更完整**：支持标注无排便，区分"未记录"和"未排便"
