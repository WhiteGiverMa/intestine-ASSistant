import { useState } from 'react'
import { Link } from 'react-router-dom'
import { analyzeData, getAnalyses } from '../api'
import type { AnalysisResult, Insight, Suggestion, Warning } from '../types'

export default function Analysis() {
  const [analysisType, setAnalysisType] = useState<'weekly' | 'monthly'>('weekly')
  const [loading, setLoading] = useState(false)
  const [result, setResult] = useState<AnalysisResult | null>(null)
  const [error, setError] = useState('')

  const handleAnalyze = async () => {
    if (!localStorage.getItem('token')) {
      setError('请先登录')
      return
    }

    setLoading(true)
    setError('')
    try {
      const res = await analyzeData(analysisType)
      setResult(res.data)
    } catch (err) {
      setError((err as Error).message)
    } finally {
      setLoading(false)
    }
  }

  const getScoreColor = (score: number) => {
    if (score >= 80) return 'text-green-500'
    if (score >= 60) return 'text-yellow-500'
    if (score >= 40) return 'text-orange-500'
    return 'text-red-500'
  }

  const getCategoryIcon = (category: string) => {
    switch (category) {
      case 'diet': return '🥗'
      case 'habit': return '🔄'
      case 'lifestyle': return '🏃'
      case 'health': return '💊'
      default: return '💡'
    }
  }

  const getInsightIcon = (type: string) => {
    switch (type) {
      case 'pattern': return '📊'
      case 'stool_type': return '💩'
      case 'frequency': return '📈'
      default: return '💡'
    }
  }

  return (
    <div className="min-h-screen flex flex-col">
      <header className="bg-white/80 backdrop-blur-sm shadow-sm sticky top-0 z-10">
        <div className="max-w-4xl mx-auto px-4 py-4 flex items-center">
          <Link to="/" className="text-gray-400 mr-4">←</Link>
          <h1 className="text-xl font-bold text-emerald-700">AI 健康分析</h1>
        </div>
      </header>

      <main className="flex-1 max-w-4xl mx-auto px-4 py-6 w-full">
        <div className="bg-white rounded-2xl p-6 shadow-lg mb-6">
          <h3 className="font-semibold text-gray-800 mb-4">选择分析周期</h3>
          <div className="flex gap-4 mb-4">
            <button
              onClick={() => setAnalysisType('weekly')}
              className={`flex-1 py-3 rounded-xl font-medium transition-colors ${
                analysisType === 'weekly'
                  ? 'bg-emerald-500 text-white'
                  : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
              }`}
            >
              周分析
            </button>
            <button
              onClick={() => setAnalysisType('monthly')}
              className={`flex-1 py-3 rounded-xl font-medium transition-colors ${
                analysisType === 'monthly'
                  ? 'bg-emerald-500 text-white'
                  : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
              }`}
            >
              月分析
            </button>
          </div>
          <button
            onClick={handleAnalyze}
            disabled={loading}
            className="w-full bg-gradient-to-r from-emerald-500 to-teal-500 text-white py-3 rounded-xl font-medium hover:from-emerald-600 hover:to-teal-600 transition-colors disabled:opacity-50"
          >
            {loading ? '分析中...' : '🤖 开始 AI 分析'}
          </button>
        </div>

        {error && (
          <div className="bg-red-100 text-red-700 p-4 rounded-xl mb-6">
            {error}
          </div>
        )}

        {result && (
          <div className="space-y-4">
            <div className="bg-white rounded-2xl p-6 shadow-lg text-center">
              <div className="text-sm text-gray-500 mb-2">肠道健康评分</div>
              <div className={`text-7xl font-bold ${getScoreColor(result.health_score)}`}>
                {result.health_score}
              </div>
              <div className="text-gray-400 mt-2">满分 100</div>
            </div>

            {result.warnings && result.warnings.length > 0 && (
              <div className="bg-red-50 border border-red-200 rounded-2xl p-4">
                <h4 className="font-semibold text-red-700 mb-2 flex items-center gap-2">
                  <span>⚠️</span> 健康提醒
                </h4>
                <ul className="space-y-2">
                  {result.warnings.map((warning: Warning, index: number) => (
                    <li key={index} className="text-sm text-red-600">
                      • {warning.message}
                    </li>
                  ))}
                </ul>
              </div>
            )}

            <div className="bg-white rounded-2xl p-6 shadow-lg">
              <h4 className="font-semibold text-gray-800 mb-4">📊 分析洞察</h4>
              <div className="space-y-4">
                {result.insights.map((insight: Insight, index: number) => (
                  <div key={index} className="flex gap-3 p-3 bg-gray-50 rounded-xl">
                    <span className="text-2xl">{getInsightIcon(insight.type)}</span>
                    <div>
                      <div className="font-medium text-gray-800">{insight.title}</div>
                      <div className="text-sm text-gray-600 mt-1">{insight.description}</div>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            <div className="bg-white rounded-2xl p-6 shadow-lg">
              <h4 className="font-semibold text-gray-800 mb-4">💡 健康建议</h4>
              <div className="space-y-3">
                {result.suggestions.map((suggestion: Suggestion, index: number) => (
                  <div key={index} className="flex gap-3 p-3 bg-emerald-50 rounded-xl">
                    <span className="text-2xl">{getCategoryIcon(suggestion.category)}</span>
                    <p className="text-sm text-gray-700 flex-1">{suggestion.suggestion}</p>
                  </div>
                ))}
              </div>
            </div>

            <div className="bg-amber-50 border border-amber-200 rounded-2xl p-4 text-center">
              <p className="text-sm text-amber-700">
                ⚠️ 以上分析仅供参考，不能替代专业医疗诊断。如有不适，请及时就医。
              </p>
            </div>
          </div>
        )}

        {!result && !error && (
          <div className="text-center py-12 text-gray-500">
            <div className="text-6xl mb-4">🤖</div>
            <p>点击上方按钮开始 AI 分析</p>
            <p className="text-sm mt-2">需要先记录排便数据才能进行分析</p>
          </div>
        )}
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
          <Link to="/stats" className="flex flex-col items-center text-gray-400 hover:text-emerald-600">
            <span className="text-xl">📊</span>
            <span className="text-xs">统计</span>
          </Link>
          <Link to="/analysis" className="flex flex-col items-center text-emerald-600">
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
