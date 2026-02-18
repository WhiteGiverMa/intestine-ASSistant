import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import 'data_page.dart';
import 'analysis_page.dart';
import 'settings_page.dart';
import 'login_page.dart';
import 'record_page.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  String _period = 'week';
  StatsSummary? _summary;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final summary = await ApiService.getStatsSummary(period: _period);
      setState(() {
        _summary = summary;
        _loading = false;
      });
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      final lowerMsg = errorMsg.toLowerCase();
      final isAuthError = lowerMsg.contains('认证') ||
          lowerMsg.contains('token') ||
          lowerMsg.contains('令牌') ||
          lowerMsg.contains('authenticated') ||
          lowerMsg.contains('unauthorized');
      if (isAuthError) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        await prefs.remove('user');
        setState(() {
          _error = '登录已过期，请重新登录';
          _loading = false;
        });
      } else {
        setState(() {
          _error = errorMsg;
          _loading = false;
        });
      }
    }
  }

  Color _getHealthScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getHealthScoreLabel(int score) {
    if (score >= 80) return '优秀';
    if (score >= 60) return '良好';
    if (score >= 40) return '一般';
    return '需关注';
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
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? _buildErrorWidget()
                        : _summary != null && _summary!.totalRecords == 0
                            ? _buildEmptyDataWidget()
                            : _buildContent(),
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
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Text('←', style: TextStyle(fontSize: 20, color: Colors.grey)),
          ),
          const SizedBox(width: 16),
          const Text(
            '数据统计',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    final isAuthError = _error!.contains('登录');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔒', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (isAuthError)
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🔑', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 8),
                    Text('去登录', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyDataWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📭', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text(
              '暂无排便数据',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              '开始记录您的排便数据，即可查看统计分析',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RecordPage()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('📝', style: TextStyle(fontSize: 18)),
                  SizedBox(width: 8),
                  Text('去记录', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPeriodToggle(),
          const SizedBox(height: 16),
          _buildHealthScore(),
          const SizedBox(height: 16),
          _buildStatsGrid(),
          const SizedBox(height: 16),
          _buildStoolTypeDistribution(),
          const SizedBox(height: 16),
          _buildTimeDistribution(),
        ],
      ),
    );
  }

  Widget _buildPeriodToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          {'value': 'week', 'label': '本周'},
          {'value': 'month', 'label': '本月'},
          {'value': 'year', 'label': '本年'},
        ].map((p) {
          final isSelected = _period == p['value'];
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _period = p['value'] as String);
                _loadStats();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2E7D32) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  p['label'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHealthScore() {
    final score = _summary?.healthScore ?? 0;
    return Container(
      padding: const EdgeInsets.all(24),
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
        children: [
          const Text('健康评分', style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(
            '$score',
            style: TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              color: _getHealthScoreColor(score),
            ),
          ),
          Text(
            _getHealthScoreLabel(score),
            style: TextStyle(
              fontSize: 18,
              color: _getHealthScoreColor(score),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('${_summary?.totalRecords ?? 0}', '记录次数', const Color(0xFF2E7D32))),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('${_summary?.avgFrequencyPerDay ?? 0}', '日均次数', const Color(0xFF1976D2))),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('${_summary?.avgDurationMinutes ?? 0}', '平均时长(分)', const Color(0xFF7B1FA2))),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        children: [
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildStoolTypeDistribution() {
    if (_summary == null) return const SizedBox.shrink();

    final distribution = _summary!.stoolTypeDistribution;
    final total = distribution.values.fold(0, (sum, v) => sum + v);
    if (total == 0) return const SizedBox.shrink();

    final emojis = ['🪨', '🥜', '🌭', '🍌', '🫘', '🥣', '💧'];

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
          const Text('粪便形态分布', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...distribution.entries.map((entry) {
            final percentage = ((entry.value / total) * 100).round();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text(emojis[int.parse(entry.key) - 1], style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  SizedBox(width: 50, child: Text('类型 ${entry.key}', style: const TextStyle(fontSize: 12))),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(width: 40, child: Text('$percentage%', style: const TextStyle(fontSize: 12))),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimeDistribution() {
    if (_summary == null) return const SizedBox.shrink();

    final time = _summary!.timeDistribution;

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
          const Text('排便时间分布', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTimeItem('🌅', '早晨', time.morning, Colors.orange),
              ),
              Expanded(
                child: _buildTimeItem('☀️', '下午', time.afternoon, Colors.amber),
              ),
              Expanded(
                child: _buildTimeItem('🌙', '晚上', time.evening, Colors.indigo),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeItem(String emoji, String label, int count, Color color) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 32)),
        const SizedBox(height: 8),
        Text('$count', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
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
            _buildNavItem('🏠', '首页', false, () => Navigator.pop(context)),
            _buildNavItem('📊', '数据', false, const DataPage()),
            _buildNavItem('🤖', '分析', false, const AnalysisPage()),
            _buildNavItem('⚙️', '设置', false, const SettingsPage()),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(String emoji, String label, bool isActive, [dynamic target]) {
    return GestureDetector(
      onTap: target != null
          ? () {
              if (target is VoidCallback) {
                target();
              } else if (target is Widget) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => target));
              }
            }
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
