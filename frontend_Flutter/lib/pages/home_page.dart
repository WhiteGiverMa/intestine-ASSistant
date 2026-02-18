import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'data_page.dart';
import 'analysis_page.dart';
import 'record_page.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _token;
  String? _nickname;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('token');
      _nickname = prefs.getString('user') != null
          ? null
          : null;
    });
  }

  Future<void> _logout() async {
    await ApiService.logout();
    setState(() {
      _token = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE8F5E9), Color(0xFFB2DFDB)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildWelcome(),
                      const SizedBox(height: 24),
                      _buildMenuGrid(),
                      const SizedBox(height: 24),
                      _buildBristolChart(),
                    ],
                  ),
                ),
              ),
              _buildBottomNav(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '肠道健康助手',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          if (_token != null)
            TextButton(
              onPressed: _logout,
              child: const Text('退出', style: TextStyle(color: Colors.grey)),
            )
          else
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  ),
                  child: const Text('登录', style: TextStyle(color: Color(0xFF2E7D32))),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                  ),
                  child: const Text('注册', style: TextStyle(color: Color(0xFF2E7D32))),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildWelcome() {
    return Column(
      children: [
        const Text('🚽', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 16),
        const Text(
          '记录您的肠道健康',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          '简单记录，智能分析，守护您的肠道健康',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildMenuGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildMenuItem('📝', '记录排便', '快速记录您的排便数据', const RecordPage())),
            const SizedBox(width: 16),
            Expanded(child: _buildMenuItem('🤖', 'AI 分析', '智能健康分析', const AnalysisPage())),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuItem(String emoji, String title, String subtitle, Widget page, {bool fullWidth = false}) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: fullWidth
            ? Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 40)),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ],
              )
            : Column(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 40)),
                  const SizedBox(height: 12),
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
      ),
    );
  }

  Widget _buildBristolChart() {
    final types = [
      {'type': 1, 'emoji': '🪨', 'desc': '硬块', 'status': '便秘'},
      {'type': 2, 'emoji': '🥜', 'desc': '结块', 'status': '轻便秘'},
      {'type': 3, 'emoji': '🌭', 'desc': '有裂纹', 'status': '正常'},
      {'type': 4, 'emoji': '🍌', 'desc': '光滑', 'status': '理想'},
      {'type': 5, 'emoji': '🫘', 'desc': '断块', 'status': '缺纤维'},
      {'type': 6, 'emoji': '🥣', 'desc': '糊状', 'status': '轻腹泻'},
      {'type': 7, 'emoji': '💧', 'desc': '液体', 'status': '腹泻'},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '布里斯托大便分类法',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: types.map((t) {
              final status = t['status'] as String;
              Color statusColor;
              if (status == '理想') {
                statusColor = Colors.green;
              } else if (status == '正常') {
                statusColor = Colors.green.shade300;
              } else if (status.contains('便秘') || status.contains('腹泻')) {
                statusColor = Colors.red;
              } else {
                statusColor = Colors.orange;
              }

              return Column(
                children: [
                  Text(t['emoji'] as String, style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 4),
                  Text('类型${t['type']}', style: const TextStyle(fontSize: 10)),
                  Text(t['desc'] as String, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(
                    status,
                    style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem('🏠', '首页', true),
            _buildNavItem('📊', '数据', false, const DataPage()),
            _buildNavItem('🤖', '分析', false, const AnalysisPage()),
            _buildNavItem('⚙️', '设置', false, const SettingsPage()),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(String emoji, String label, bool isActive, [Widget? page]) {
    return GestureDetector(
      onTap: page != null
          ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => page))
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isActive ? const Color(0xFF2E7D32) : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
