import { useState, useEffect } from 'react'
import { Link } from 'react-router-dom'
import { createRecord, getUserSettings, updateUserSettings } from '../api'

const COLORS = [
  { value: 'brown', label: '棕色' },
  { value: 'dark_brown', label: '深棕' },
  { value: 'light_brown', label: '浅棕' },
  { value: 'green', label: '绿色' },
  { value: 'yellow', label: '黄色' },
  { value: 'black', label: '黑色' },
  { value: 'red', label: '红色' },
]

const FEELINGS = [
  { value: 'smooth', label: '顺畅' },
  { value: 'difficult', label: '困难' },
  { value: 'painful', label: '疼痛' },
  { value: 'urgent', label: '急迫' },
  { value: 'incomplete', label: '不尽' },
]

const SYMPTOMS = ['腹痛', '腹胀', '恶心', '便血', '粘液']

function randomInt(min: number, max: number): number {
  return Math.floor(Math.random() * (max - min + 1)) + min
}

function randomChoice<T>(arr: T[]): T {
  return arr[Math.floor(Math.random() * arr.length)]
}

function generateRandomRecords(count: number, startDate: Date) {
  const records = []
  for (let i = 0; i < count; i++) {
    const date = new Date(startDate)
    date.setDate(date.getDate() + i)

    const record = {
      record_date: date.toISOString().split('T')[0],
      record_time: `${String(randomInt(6, 22)).padStart(2, '0')}:${String(randomInt(0, 59)).padStart(2, '0')}`,
      duration_minutes: randomInt(1, 15),
      stool_type: randomInt(1, 7),
      color: randomChoice(COLORS).value,
      smell_level: randomInt(1, 5),
      feeling: randomChoice(FEELINGS).value,
      symptoms: Math.random() > 0.6 ? [randomChoice(SYMPTOMS)] : [],
      notes: ''
    }
    records.push(record)
  }
  return records
}

export default function Settings() {
  const [devMode, setDevMode] = useState(false)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [generating, setGenerating] = useState(false)
  const [generateCount, setGenerateCount] = useState(7)
  const [message, setMessage] = useState('')

  useEffect(() => {
    const loadSettings = async () => {
      if (!localStorage.getItem('token')) {
        setLoading(false)
        return
      }

      try {
        const res = await getUserSettings()
        setDevMode(res.data?.dev_mode || false)
      } catch (err) {
        console.error('加载设置失败:', err)
      } finally {
        setLoading(false)
      }
    }

    loadSettings()
  }, [])

  const handleDevModeToggle = async () => {
    if (!localStorage.getItem('token')) {
      setMessage('请先登录')
      return
    }

    const newDevMode = !devMode
    setDevMode(newDevMode)
    setSaving(true)
    setMessage('')

    try {
      await updateUserSettings({ dev_mode: newDevMode })
    } catch (err) {
      setDevMode(!newDevMode)
      setMessage((err as Error).message)
    } finally {
      setSaving(false)
    }
  }

  const handleGenerateTestData = async () => {
    if (!localStorage.getItem('token')) {
      setMessage('请先登录')
      return
    }

    setGenerating(true)
    setMessage('')

    try {
      const records = generateRandomRecords(generateCount, new Date())
      let successCount = 0

      for (const record of records) {
        try {
          await createRecord(record)
          successCount++
        } catch {
        }
      }

      setMessage(`成功生成 ${successCount}/${generateCount} 条测试数据`)
    } catch (err) {
      setMessage((err as Error).message)
    } finally {
      setGenerating(false)
    }
  }

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-gray-500">加载�?..</div>
      </div>
    )
  }

  return (
    <div className="min-h-screen flex flex-col">
      <header className="bg-white/80 backdrop-blur-sm shadow-sm sticky top-0 z-10">
        <div className="max-w-4xl mx-auto px-4 py-4 flex items-center">
          <Link to="/" className="text-gray-400 mr-4">�?/Link>
          <h1 className="text-xl font-bold text-emerald-700">设置</h1>
        </div>
      </header>

      <main className="flex-1 max-w-4xl mx-auto px-4 py-6 w-full">
        <div className="bg-white rounded-2xl p-6 shadow-lg mb-4">
          <div className="flex items-center justify-between">
            <div>
              <h3 className="font-semibold text-gray-800">开发者模�?/h3>
              <p className="text-sm text-gray-500 mt-1">启用测试和调试工�?/p>
            </div>
            <button
              onClick={handleDevModeToggle}
              disabled={saving}
              className={`relative w-14 h-8 rounded-full transition-colors ${
                devMode ? 'bg-emerald-500' : 'bg-gray-300'
              } ${saving ? 'opacity-50' : ''}`}
            >
              <span
                className={`absolute top-1 w-6 h-6 bg-white rounded-full shadow transition-transform ${
                  devMode ? 'translate-x-7' : 'translate-x-1'
                }`}
              />
            </button>
          </div>
        </div>

        {devMode && (
          <div className="bg-white rounded-2xl p-6 shadow-lg">
            <h3 className="font-semibold text-gray-800 mb-4 flex items-center gap-2">
              <span>🛠�?/span> 开发者工具包
            </h3>

            <div className="border-t pt-4">
              <h4 className="font-medium text-gray-700 mb-3">测试数据生成�?/h4>
              <p className="text-sm text-gray-500 mb-4">
                生成连续日期的随机排便数据，用于测试AI分析功能
              </p>

              <div className="flex items-center gap-4 mb-4">
                <label className="text-sm text-gray-600">生成天数�?/label>
                <input
                  type="number"
                  min="1"
                  max="30"
                  value={generateCount}
                  onChange={e => setGenerateCount(Math.min(30, Math.max(1, parseInt(e.target.value) || 1)))}
                  className="w-20 px-3 py-2 border rounded-lg focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500"
                />
                <span className="text-sm text-gray-500">�?/span>
              </div>

              <div className="bg-gray-50 rounded-xl p-4 mb-4">
                <h5 className="text-sm font-medium text-gray-700 mb-2">将生成以下随机数据：</h5>
                <ul className="text-sm text-gray-600 space-y-1">
                  <li>�?日期：从今天开始连�?{generateCount} �?/li>
                  <li>�?时间：随�?06:00 - 22:59</li>
                  <li>�?时长：随�?1-15 分钟</li>
                  <li>�?粪便形态：随机类型 1-7</li>
                  <li>�?颜色：随机选择</li>
                  <li>�?气味等级：随�?1-5</li>
                  <li>�?排便感受：随机选择</li>
                  <li>�?伴随症状�?0%概率出现</li>
                </ul>
              </div>

              {message && (
                <div className={`text-center py-2 rounded-lg mb-4 ${
                  message.includes('成功') ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'
                }`}>
                  {message}
                </div>
              )}

              <button
                onClick={handleGenerateTestData}
                disabled={generating}
                className="w-full bg-gradient-to-r from-purple-500 to-indigo-500 text-white py-3 rounded-xl font-medium hover:from-purple-600 hover:to-indigo-600 transition-colors disabled:opacity-50"
              >
                {generating ? '生成�?..' : '🎲 随机生成排便数据'}
              </button>
            </div>
          </div>
        )}

        {!devMode && (
          <div className="text-center py-12 text-gray-500">
            <div className="text-6xl mb-4">⚙️</div>
            <p>开启开发者模式以使用测试工具</p>
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
          <Link to="/analysis" className="flex flex-col items-center text-gray-400 hover:text-emerald-600">
            <span className="text-xl">🤖</span>
            <span className="text-xs">分析</span>
          </Link>
          <Link to="/settings" className="flex flex-col items-center text-emerald-600">
            <span className="text-xl">⚙️</span>
            <span className="text-xs">设置</span>
          </Link>
        </div>
      </nav>
    </div>
  )
}
