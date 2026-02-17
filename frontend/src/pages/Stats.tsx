import { useState, useEffect } from 'react'
import { Link } from 'react-router-dom'
import { getStatsSummary, getStatsTrends } from '../api'
import type { StatsSummary } from '../types'

export default function Stats() {
  const [period, setPeriod] = useState<'week' | 'month' | 'year'>('week')
  const [summary, setSummary] = useState<StatsSummary | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    loadStats()
  }, [period])

  const loadStats = async () => {
    if (!localStorage.getItem('token')) {
      setError('请先登录')
      setLoading(false)
      return
    }

    setLoading(true)
    try {
      const res = await getStatsSummary(period)
      setSummary(res.data)
      setError('')
    } catch (err) {
      const errorMsg = (err as Error).message
      if (errorMsg.includes('认证') || errorMsg.includes('token') || errorMsg.includes('令牌')) {
        localStorage.removeItem('token')
        localStorage.removeItem('user')
        setError('登录已过期，请重新登录')
      } else {
        setError(errorMsg)
      }
    } finally {
      setLoading(false)
    }
  }

  const getHealthScoreColor = (score: number) => {
    if (score >= 80) return 'text-green-500'
    if (score >= 60) return 'text-yellow-500'
    return 'text-red-500'
  }

  const getHealthScoreLabel = (score: number) => {
    if (score >= 80) return '优秀'
    if (score >= 60) return '良好'
    if (score >= 40) return '一般'
    return '需关注'
  }

  return (
    <div className="min-h-screen flex flex-col">
      <header className="bg-white/80 backdrop-blur-sm shadow-sm sticky top-0 z-10">
        <div className="max-w-4xl mx-auto px-4 py-4 flex items-center">
          <Link to="/" className="text-gray-400 mr-4">←</Link>
          <h1 className="text-xl font-bold text-emerald-700">数据统计</h1>
        </div>
      </header>

      <main className="flex-1 max-w-4xl mx-auto px-4 py-6 w-full">
        <div className="flex mb-6 bg-white rounded-xl p-1 shadow">
          {(['week', 'month', 'year'] as const).map(p => (
            <button
              key={p}
              onClick={() => setPeriod(p)}
              className={`flex-1 py-2 rounded-lg text-sm font-medium transition-colors ${
                period === p ? 'bg-emerald-500 text-white' : 'text-gray-600'
              }`}
            >
              {p === 'week' ? '本周' : p === 'month' ? '本月' : '本年'}
            </button>
          ))}
        </div>

        {loading ? (
          <div className="text-center py-12 text-gray-500">加载中...</div>
        ) : error ? (
          <div className="text-center py-12">
            <div className="text-6xl mb-4">🔒</div>
            <p className="text-red-500 mb-4">{error}</p>
            {error.includes('登录') && (
              <Link
                to="/login"
                className="inline-flex items-center gap-2 bg-emerald-500 text-white px-6 py-3 rounded-xl font-medium hover:bg-emerald-600 transition-colors"
              >
                <span>🔑</span>
                <span>去登录</span>
              </Link>
            )}
          </div>
        ) : summary && summary.total_records === 0 ? (
          <div className="text-center py-12">
            <div className="text-6xl mb-4">📭</div>
            <h3 className="text-xl font-semibold text-gray-700 mb-2">暂无排便数据</h3>
            <p className="text-gray-500 mb-6">开始记录您的排便数据，即可查看统计分析</p>
            <Link
              to="/record"
              className="inline-flex items-center gap-2 bg-emerald-500 text-white px-6 py-3 rounded-xl font-medium hover:bg-emerald-600 transition-colors"
            >
              <span>📝</span>
              <span>去记录</span>
            </Link>
          </div>
        ) : summary ? (
          <div className="space-y-4">
            <div className="bg-white rounded-2xl p-6 shadow-lg text-center">
              <div className="text-sm text-gray-500 mb-2">健康评分</div>
              <div className={`text-6xl font-bold ${getHealthScoreColor(summary.health_score)}`}>
                {summary.health_score}
              </div>
              <div className={`text-lg mt-1 ${getHealthScoreColor(summary.health_score)}`}>
                {getHealthScoreLabel(summary.health_score)}
              </div>
            </div>

            <div className="grid grid-cols-3 gap-4">
              <div className="bg-white rounded-2xl p-4 shadow-lg text-center">
                <div className="text-3xl font-bold text-emerald-600">{summary.total_records}</div>
                <div className="text-sm text-gray-500 mt-1">记录次数</div>
              </div>
              <div className="bg-white rounded-2xl p-4 shadow-lg text-center">
                <div className="text-3xl font-bold text-blue-600">{summary.avg_frequency_per_day}</div>
                <div className="text-sm text-gray-500 mt-1">日均次数</div>
              </div>
              <div className="bg-white rounded-2xl p-4 shadow-lg text-center">
                <div className="text-3xl font-bold text-purple-600">{summary.avg_duration_minutes}</div>
                <div className="text-sm text-gray-500 mt-1">平均时长(分)</div>
              </div>
            </div>

            <div className="bg-white rounded-2xl p-6 shadow-lg">
              <h3 className="font-semibold text-gray-800 mb-4">粪便形态分布</h3>
              <div className="space-y-2">
                {Object.entries(summary.stool_type_distribution).map(([type, count]) => {
                  const total = Object.values(summary.stool_type_distribution).reduce((a, b) => a + b, 0)
                  const percentage = total > 0 ? Math.round((count / total) * 100) : 0
                  const emojis = ['🪨', '🥜', '🌭', '🍌', '🫘', '🥣', '💧']
                  return (
                    <div key={type} className="flex items-center gap-2">
                      <span className="text-lg">{emojis[parseInt(type) - 1]}</span>
                      <span className="text-sm text-gray-600 w-16">类型 {type}</span>
                      <div className="flex-1 bg-gray-100 rounded-full h-4 overflow-hidden">
                        <div
                          className="bg-emerald-500 h-full rounded-full transition-all"
                          style={{ width: `${percentage}%` }}
                        />
                      </div>
                      <span className="text-sm text-gray-600 w-12 text-right">{percentage}%</span>
                    </div>
                  )
                })}
              </div>
            </div>

            <div className="bg-white rounded-2xl p-6 shadow-lg">
              <h3 className="font-semibold text-gray-800 mb-4">排便时间分布</h3>
              <div className="grid grid-cols-3 gap-4">
                <div className="text-center">
                  <div className="text-3xl mb-1">🌅</div>
                  <div className="text-2xl font-bold text-orange-500">{summary.time_distribution.morning}</div>
                  <div className="text-sm text-gray-500">早晨</div>
                </div>
                <div className="text-center">
                  <div className="text-3xl mb-1">☀️</div>
                  <div className="text-2xl font-bold text-yellow-500">{summary.time_distribution.afternoon}</div>
                  <div className="text-sm text-gray-500">下午</div>
                </div>
                <div className="text-center">
                  <div className="text-3xl mb-1">🌙</div>
                  <div className="text-2xl font-bold text-indigo-500">{summary.time_distribution.evening}</div>
                  <div className="text-sm text-gray-500">晚上</div>
                </div>
              </div>
            </div>
          </div>
        ) : null}
      </main>

      <nav className="bg-white border-t sticky bottom-0">
        <div className="max-w-4xl mx-auto px-4 py-2 flex justify-around">
          <Link to="/" className="flex flex-col items-center text-gray-400 hover:text-emerald-600">
            <span className="text-xl">🏠</span>
            <span className="text-xs">首页</span>
          </Link>
          <Link to="/record" className="flex flex-col items-center text-gray-400 hover:text-emerald-600">
            <span className="text-xl">📝</span>
            <span className="text-xs">记录</span>
          </Link>
          <Link to="/stats" className="flex flex-col items-center text-emerald-600">
            <span className="text-xl">📊</span>
            <span className="text-xs">统计</span>
          </Link>
          <Link to="/analysis" className="flex flex-col items-center text-gray-400 hover:text-emerald-600">
            <span className="text-xl">🤖</span>
            <span className="text-xs">分析</span>
          </Link>
          <Link to="/settings" className="flex flex-col items-center text-gray-400 hover:text-emerald-600">
            <span className="text-xl">⚙️</span>
            <span className="text-xs">设置</span>
          </Link>
        </div>
      </nav>
    </div>
  )
}
