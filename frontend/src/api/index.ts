const API_BASE = 'http://localhost:8001/api/v1'

function getAuthHeaders(): HeadersInit {
  const token = localStorage.getItem('token')
  return {
    'Content-Type': 'application/json',
    ...(token ? { 'Authorization': `Bearer ${token}` } : {})
  }
}

export async function register(email: string, password: string, nickname?: string) {
  const res = await fetch(`${API_BASE}/auth/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password, nickname })
  })
  if (!res.ok) {
    const error = await res.json()
    throw new Error(error.detail || '注册失败')
  }
  return res.json()
}

export async function login(email: string, password: string) {
  const res = await fetch(`${API_BASE}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password })
  })
  if (!res.ok) {
    const error = await res.json()
    throw new Error(error.detail || '登录失败')
  }
  return res.json()
}

export async function createRecord(data: {
  record_date: string
  record_time: string
  duration_minutes?: number
  stool_type?: number
  color?: string
  smell_level?: number
  feeling?: string
  symptoms?: string[]
  notes?: string
}) {
  const res = await fetch(`${API_BASE}/records`, {
    method: 'POST',
    headers: getAuthHeaders(),
    body: JSON.stringify(data)
  })
  if (!res.ok) {
    const error = await res.json()
    throw new Error(error.detail || '创建记录失败')
  }
  return res.json()
}

export async function getRecords(startDate?: string, endDate?: string, page = 1, limit = 20) {
  const params = new URLSearchParams()
  if (startDate) params.append('start_date', startDate)
  if (endDate) params.append('end_date', endDate)
  params.append('page', String(page))
  params.append('limit', String(limit))
  
  const res = await fetch(`${API_BASE}/records?${params}`, {
    headers: getAuthHeaders()
  })
  if (!res.ok) {
    const error = await res.json()
    throw new Error(error.detail || '获取记录失败')
  }
  return res.json()
}

export async function deleteRecord(recordId: string) {
  const res = await fetch(`${API_BASE}/records/${recordId}`, {
    method: 'DELETE',
    headers: getAuthHeaders()
  })
  if (!res.ok) {
    const error = await res.json()
    throw new Error(error.detail || '删除记录失败')
  }
  return res.json()
}

export async function getStatsSummary(period: string = 'week') {
  const res = await fetch(`${API_BASE}/stats/summary?period=${period}`, {
    headers: getAuthHeaders()
  })
  if (!res.ok) {
    const error = await res.json()
    throw new Error(error.detail || '获取统计失败')
  }
  return res.json()
}

export async function getStatsTrends(metric: string = 'frequency', period: string = 'month') {
  const res = await fetch(`${API_BASE}/stats/trends?metric=${metric}&period=${period}`, {
    headers: getAuthHeaders()
  })
  if (!res.ok) {
    const error = await res.json()
    throw new Error(error.detail || '获取趋势失败')
  }
  return res.json()
}

export async function analyzeData(analysisType: string = 'weekly', startDate?: string, endDate?: string) {
  const res = await fetch(`${API_BASE}/ai/analyze`, {
    method: 'POST',
    headers: getAuthHeaders(),
    body: JSON.stringify({
      analysis_type: analysisType,
      start_date: startDate,
      end_date: endDate
    })
  })
  if (!res.ok) {
    const error = await res.json()
    throw new Error(error.detail || '分析失败')
  }
  return res.json()
}

export async function getAnalyses() {
  const res = await fetch(`${API_BASE}/ai/analyses`, {
    headers: getAuthHeaders()
  })
  if (!res.ok) {
    const error = await res.json()
    throw new Error(error.detail || '获取分析历史失败')
  }
  return res.json()
}
