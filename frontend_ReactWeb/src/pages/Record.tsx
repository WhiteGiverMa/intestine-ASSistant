import { useState, useEffect } from 'react'
import { Link } from 'react-router-dom'
import { createRecord } from '../api'

export default function Record() {
  const [activeTab, setActiveTab] = useState<'manual' | 'timer'>('manual')
  const [isTimerRunning, setIsTimerRunning] = useState(false)
  const [timerSeconds, setTimerSeconds] = useState(0)
  const [formData, setFormData] = useState({
    record_date: new Date().toISOString().split('T')[0],
    record_time: new Date().toTimeString().slice(0, 5),
    duration_minutes: 0,
    stool_type: 4,
    color: 'brown',
    smell_level: 2,
    feeling: 'smooth',
    symptoms: [] as string[],
    notes: ''
  })
  const [submitting, setSubmitting] = useState(false)
  const [message, setMessage] = useState('')

  useEffect(() => {
    let interval: number
    if (isTimerRunning) {
      interval = window.setInterval(() => {
        setTimerSeconds(s => s + 1)
      }, 1000)
    }
    return () => clearInterval(interval)
  }, [isTimerRunning])

  const formatTime = (seconds: number) => {
    const mins = Math.floor(seconds / 60)
    const secs = seconds % 60
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`
  }

  const handleStartTimer = () => {
    setIsTimerRunning(true)
    setTimerSeconds(0)
  }

  const handleStopTimer = () => {
    setIsTimerRunning(false)
    setFormData(prev => ({
      ...prev,
      duration_minutes: Math.ceil(timerSeconds / 60),
      record_time: new Date().toTimeString().slice(0, 5)
    }))
  }

  const handleSubmit = async () => {
    if (!localStorage.getItem('token')) {
      setMessage('请先登录')
      return
    }

    setSubmitting(true)
    try {
      await createRecord({
        record_date: formData.record_date,
        record_time: formData.record_time,
        duration_minutes: formData.duration_minutes || undefined,
        stool_type: formData.stool_type,
        color: formData.color,
        smell_level: formData.smell_level,
        feeling: formData.feeling,
        symptoms: formData.symptoms.length > 0 ? formData.symptoms : undefined,
        notes: formData.notes || undefined
      })
      setMessage('记录成功！')
      setFormData({
        record_date: new Date().toISOString().split('T')[0],
        record_time: new Date().toTimeString().slice(0, 5),
        duration_minutes: 0,
        stool_type: 4,
        color: 'brown',
        smell_level: 2,
        feeling: 'smooth',
        symptoms: [],
        notes: ''
      })
    } catch (err) {
      setMessage((err as Error).message)
    } finally {
      setSubmitting(false)
    }
  }

  const toggleSymptom = (symptom: string) => {
    setFormData(prev => ({
      ...prev,
      symptoms: prev.symptoms.includes(symptom)
        ? prev.symptoms.filter(s => s !== symptom)
        : [...prev.symptoms, symptom]
    }))
  }

  return (
    <div className="min-h-screen flex flex-col">
      <header className="bg-white/80 backdrop-blur-sm shadow-sm sticky top-0 z-10">
        <div className="max-w-4xl mx-auto px-4 py-4 flex items-center">
          <Link to="/" className="text-gray-400 mr-4">←</Link>
          <h1 className="text-xl font-bold text-emerald-700">记录排便</h1>
        </div>
      </header>

      <main className="flex-1 max-w-4xl mx-auto px-4 py-6 w-full">
        <div className="flex mb-6 bg-white rounded-xl p-1 shadow">
          <button
            onClick={() => setActiveTab('manual')}
            className={`flex-1 py-2 rounded-lg text-sm font-medium transition-colors ${
              activeTab === 'manual' ? 'bg-emerald-500 text-white' : 'text-gray-600'
            }`}
          >
            手动输入
          </button>
          <button
            onClick={() => setActiveTab('timer')}
            className={`flex-1 py-2 rounded-lg text-sm font-medium transition-colors ${
              activeTab === 'timer' ? 'bg-emerald-500 text-white' : 'text-gray-600'
            }`}
          >
            计时器
          </button>
        </div>

        {activeTab === 'timer' && (
          <div className="bg-white rounded-2xl p-6 shadow-lg mb-6 text-center">
            <div className="text-6xl font-mono font-bold text-emerald-600 mb-6">
              {formatTime(timerSeconds)}
            </div>
            {!isTimerRunning ? (
              <button
                onClick={handleStartTimer}
                className="bg-emerald-500 text-white px-8 py-3 rounded-full font-medium hover:bg-emerald-600 transition-colors"
              >
                开始计时
              </button>
            ) : (
              <button
                onClick={handleStopTimer}
                className="bg-red-500 text-white px-8 py-3 rounded-full font-medium hover:bg-red-600 transition-colors"
              >
                停止计时
              </button>
            )}
            {formData.duration_minutes > 0 && !isTimerRunning && (
              <p className="mt-4 text-gray-600">
                已记录时长: {formData.duration_minutes} 分钟
              </p>
            )}
          </div>
        )}

        <div className="bg-white rounded-2xl p-6 shadow-lg space-y-6">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">日期</label>
              <input
                type="date"
                value={formData.record_date}
                onChange={e => setFormData(prev => ({ ...prev, record_date: e.target.value }))}
                className="w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">时间</label>
              <input
                type="time"
                value={formData.record_time}
                onChange={e => setFormData(prev => ({ ...prev, record_time: e.target.value }))}
                className="w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500"
              />
            </div>
          </div>

          {activeTab === 'manual' && (
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">时长（分钟）</label>
              <input
                type="number"
                min="1"
                max="60"
                value={formData.duration_minutes || ''}
                onChange={e => setFormData(prev => ({ ...prev, duration_minutes: parseInt(e.target.value) || 0 }))}
                placeholder="可选"
                className="w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500"
              />
            </div>
          )}

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">粪便形态（布里斯托分类）</label>
            <div className="grid grid-cols-7 gap-2">
              {[1, 2, 3, 4, 5, 6, 7].map(type => (
                <button
                  key={type}
                  onClick={() => setFormData(prev => ({ ...prev, stool_type: type }))}
                  className={`p-2 rounded-lg text-center transition-colors ${
                    formData.stool_type === type
                      ? 'bg-emerald-500 text-white'
                      : 'bg-gray-100 hover:bg-gray-200'
                  }`}
                >
                  <div className="text-lg">
                    {['🪨', '🥜', '🌭', '🍌', '🫘', '🥣', '💧'][type - 1]}
                  </div>
                  <div className="text-xs">{type}</div>
                </button>
              ))}
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">颜色</label>
            <div className="flex flex-wrap gap-2">
              {[
                { value: 'brown', label: '棕色', color: 'bg-amber-700' },
                { value: 'dark_brown', label: '深棕', color: 'bg-amber-900' },
                { value: 'light_brown', label: '浅棕', color: 'bg-amber-500' },
                { value: 'green', label: '绿色', color: 'bg-green-600' },
                { value: 'yellow', label: '黄色', color: 'bg-yellow-500' },
                { value: 'black', label: '黑色', color: 'bg-gray-800' },
                { value: 'red', label: '红色', color: 'bg-red-600' },
              ].map(item => (
                <button
                  key={item.value}
                  onClick={() => setFormData(prev => ({ ...prev, color: item.value }))}
                  className={`px-3 py-1 rounded-full text-sm flex items-center gap-1 transition-colors ${
                    formData.color === item.value
                      ? 'ring-2 ring-emerald-500 ring-offset-2'
                      : ''
                  }`}
                >
                  <span className={`w-3 h-3 rounded-full ${item.color}`}></span>
                  {item.label}
                </button>
              ))}
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">气味</label>
            <div className="flex gap-2">
              {[1, 2, 3, 4, 5].map(level => (
                <button
                  key={level}
                  onClick={() => setFormData(prev => ({ ...prev, smell_level: level }))}
                  className={`flex-1 py-2 rounded-lg text-sm transition-colors ${
                    formData.smell_level === level
                      ? 'bg-emerald-500 text-white'
                      : 'bg-gray-100 hover:bg-gray-200'
                  }`}
                >
                  {['无', '轻微', '一般', '较重', '严重'][level - 1]}
                </button>
              ))}
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">排便感受</label>
            <div className="flex flex-wrap gap-2">
              {[
                { value: 'smooth', label: '顺畅', emoji: '😊' },
                { value: 'difficult', label: '困难', emoji: '😣' },
                { value: 'painful', label: '疼痛', emoji: '😫' },
                { value: 'urgent', label: '急迫', emoji: '😰' },
                { value: 'incomplete', label: '不尽', emoji: '😕' },
              ].map(item => (
                <button
                  key={item.value}
                  onClick={() => setFormData(prev => ({ ...prev, feeling: item.value }))}
                  className={`px-4 py-2 rounded-lg text-sm flex items-center gap-1 transition-colors ${
                    formData.feeling === item.value
                      ? 'bg-emerald-500 text-white'
                      : 'bg-gray-100 hover:bg-gray-200'
                  }`}
                >
                  <span>{item.emoji}</span>
                  {item.label}
                </button>
              ))}
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">伴随症状</label>
            <div className="flex flex-wrap gap-2">
              {['腹痛', '腹胀', '恶心', '便血', '粘液'].map(symptom => (
                <button
                  key={symptom}
                  onClick={() => toggleSymptom(symptom)}
                  className={`px-3 py-1 rounded-full text-sm transition-colors ${
                    formData.symptoms.includes(symptom)
                      ? 'bg-emerald-500 text-white'
                      : 'bg-gray-100 hover:bg-gray-200'
                  }`}
                >
                  {symptom}
                </button>
              ))}
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">备注</label>
            <textarea
              value={formData.notes}
              onChange={e => setFormData(prev => ({ ...prev, notes: e.target.value }))}
              placeholder="可选备注..."
              rows={2}
              className="w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500"
            />
          </div>

          {message && (
            <div className={`text-center py-2 rounded-lg ${
              message.includes('成功') ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'
            }`}>
              {message}
            </div>
          )}

          <button
            onClick={handleSubmit}
            disabled={submitting}
            className="w-full bg-emerald-500 text-white py-3 rounded-xl font-medium hover:bg-emerald-600 transition-colors disabled:opacity-50"
          >
            {submitting ? '保存中...' : '保存记录'}
          </button>
        </div>
      </main>

      <nav className="bg-white border-t sticky bottom-0">
        <div className="max-w-4xl mx-auto px-4 py-2 flex justify-around">
          <Link to="/" className="flex flex-col items-center text-gray-400 hover:text-emerald-600">
            <span className="text-xl">🏠</span>
            <span className="text-xs">首页</span>
          </Link>
          <Link to="/record" className="flex flex-col items-center text-emerald-600">
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
          <Link to="/settings" className="flex flex-col items-center text-gray-400 hover:text-emerald-600">
            <span className="text-xl">⚙️</span>
            <span className="text-xs">设置</span>
          </Link>
        </div>
      </nav>
    </div>
  )
}
