import { Link } from 'react-router-dom'

export default function Home() {
  const isLoggedIn = localStorage.getItem('token')

  return (
    <div className="min-h-screen flex flex-col">
      <header className="bg-white/80 backdrop-blur-sm shadow-sm sticky top-0 z-10">
        <div className="max-w-4xl mx-auto px-4 py-4 flex justify-between items-center">
          <h1 className="text-xl font-bold text-emerald-700">肠道健康助手</h1>
          <div className="flex gap-3">
            {isLoggedIn ? (
              <button
                onClick={() => {
                  localStorage.removeItem('token')
                  window.location.reload()
                }}
                className="text-sm text-gray-600 hover:text-gray-800"
              >
                退出
              </button>
            ) : (
              <>
                <Link to="/login" className="text-sm text-emerald-600 hover:text-emerald-700">
                  登录
                </Link>
                <Link to="/register" className="text-sm text-emerald-600 hover:text-emerald-700">
                  注册
                </Link>
              </>
            )}
          </div>
        </div>
      </header>

      <main className="flex-1 max-w-4xl mx-auto px-4 py-6 w-full">
        <div className="text-center mb-8">
          <div className="text-6xl mb-4">🚽</div>
          <h2 className="text-2xl font-bold text-gray-800 mb-2">记录您的肠道健康</h2>
          <p className="text-gray-600">简单记录，智能分析，守护您的肠道健康</p>
        </div>

        <div className="grid grid-cols-2 gap-4 mb-8">
          <Link
            to="/record"
            className="bg-white rounded-2xl p-6 shadow-lg hover:shadow-xl transition-shadow text-center"
          >
            <div className="text-4xl mb-3">📝</div>
            <h3 className="font-semibold text-gray-800">记录排便</h3>
            <p className="text-sm text-gray-500 mt-1">手动输入或计时记录</p>
          </Link>

          <Link
            to="/stats"
            className="bg-white rounded-2xl p-6 shadow-lg hover:shadow-xl transition-shadow text-center"
          >
            <div className="text-4xl mb-3">📊</div>
            <h3 className="font-semibold text-gray-800">数据统计</h3>
            <p className="text-sm text-gray-500 mt-1">查看排便趋势</p>
          </Link>

          <Link
            to="/analysis"
            className="bg-white rounded-2xl p-6 shadow-lg hover:shadow-xl transition-shadow text-center col-span-2"
          >
            <div className="text-4xl mb-3">🤖</div>
            <h3 className="font-semibold text-gray-800">AI 健康分析</h3>
            <p className="text-sm text-gray-500 mt-1">智能分析您的肠道健康状况</p>
          </Link>
        </div>

        <div className="bg-white rounded-2xl p-6 shadow-lg">
          <h3 className="font-semibold text-gray-800 mb-4">布里斯托大便分类法</h3>
          <div className="grid grid-cols-7 gap-2 text-center">
            {[
              { type: 1, emoji: '🪨', desc: '硬块', status: '便秘' },
              { type: 2, emoji: '🥜', desc: '结块', status: '轻便秘' },
              { type: 3, emoji: '🌭', desc: '有裂纹', status: '正常' },
              { type: 4, emoji: '🍌', desc: '光滑', status: '理想' },
              { type: 5, emoji: '🫘', desc: '断块', status: '缺纤维' },
              { type: 6, emoji: '🥣', desc: '糊状', status: '轻腹泻' },
              { type: 7, emoji: '💧', desc: '液体', status: '腹泻' },
            ].map((item) => (
              <div key={item.type} className="p-2 rounded-lg bg-gray-50">
                <div className="text-2xl">{item.emoji}</div>
                <div className="text-xs font-medium mt-1">类型{item.type}</div>
                <div className="text-xs text-gray-500">{item.desc}</div>
                <div className={`text-xs mt-1 ${
                  item.status === '理想' ? 'text-green-600 font-medium' :
                  item.status === '正常' ? 'text-green-500' :
                  item.status.includes('便秘') || item.status.includes('腹泻') ? 'text-red-500' :
                  'text-yellow-500'
                }`}>
                  {item.status}
                </div>
              </div>
            ))}
          </div>
        </div>
      </main>

      <nav className="bg-white border-t sticky bottom-0">
        <div className="max-w-4xl mx-auto px-4 py-2 flex justify-around">
          <Link to="/" className="flex flex-col items-center text-emerald-600">
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
          <Link to="/settings" className="flex flex-col items-center text-gray-400 hover:text-emerald-600">
            <span className="text-xl">⚙️</span>
            <span className="text-xs">设置</span>
          </Link>
        </div>
      </nav>
    </div>
  )
}
