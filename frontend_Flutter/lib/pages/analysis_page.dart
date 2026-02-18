import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import 'data_page.dart';
import 'settings_page.dart';
import 'login_page.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  String _analysisType = 'weekly';
  bool _loading = false;
  AnalysisResult? _result;
  String? _error;

  Future<void> _analyze() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await ApiService.analyzeData(analysisType: _analysisType);
      setState(() {
        _result = result;
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

  bool _isAuthError() {
    return _error != null &&
        (_error!.contains('登录') || _error!.contains('过期'));
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    if (score >= 40) return Colors.deepOrange;
    return Colors.red;
  }

  String _getCategoryIcon(String category) {
    switch (category) {
      case 'diet': return '🥗';
      case 'habit': return '🔄';
      case 'lifestyle': return '🏃';
      case 'health': return '💊';
      default: return '💡';
    }
  }

  String _getInsightIcon(String type) {
    switch (type) {
      case 'pattern': return '📊';
      case 'stool_type': return '💩';
      case 'frequency': return '📈';
      default: return '💡';
    }
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
                      _buildAnalysisOptions(),
                      const SizedBox(height: 16),
                      if (_loading)
                        const Center(child: CircularProgressIndicator())
                      else if (_error != null)
                        _buildError()
                      else if (_result != null)
                        _buildResult()
                      else
                        _buildPlaceholder(),
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
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Text('←', style: TextStyle(fontSize: 20, color: Colors.grey)),
          ),
          const SizedBox(width: 16),
          const Text(
            'AI 健康分析',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisOptions() {
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
          const Text('选择分析周期', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _analysisType = 'weekly'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _analysisType == 'weekly' ? const Color(0xFF2E7D32) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '周分析',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _analysisType == 'weekly' ? Colors.white : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _analysisType = 'monthly'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _analysisType == 'monthly' ? const Color(0xFF2E7D32) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '月分析',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _analysisType == 'monthly' ? Colors.white : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _analyze,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(_loading ? '分析中...' : '🤖 开始 AI 分析', style: const TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    final isAuthError = _isAuthError();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isAuthError ? Colors.orange.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(isAuthError ? '🔒' : '❌', style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: TextStyle(color: isAuthError ? Colors.orange : Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          if (isAuthError) ...[
            const SizedBox(height: 24),
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
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          const Text('🤖', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text('点击上方按钮开始 AI 分析', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          Text('需要先记录排便数据才能进行分析', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildResult() {
    return Column(
      children: [
        _buildHealthScore(),
        if (_result!.warnings.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildWarnings(),
        ],
        const SizedBox(height: 16),
        _buildInsights(),
        const SizedBox(height: 16),
        _buildSuggestions(),
        const SizedBox(height: 16),
        _buildDisclaimer(),
      ],
    );
  }

  Widget _buildHealthScore() {
    final score = _result!.healthScore;
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
          const Text('肠道健康评分', style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(
            '$score',
            style: TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.bold,
              color: _getScoreColor(score),
            ),
          ),
          const Text('满分 100', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildWarnings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('⚠️', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Text('健康提醒', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
            ],
          ),
          const SizedBox(height: 12),
          ..._result!.warnings.map((w) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(color: Colors.red)),
                Expanded(child: Text(w.message, style: const TextStyle(color: Colors.red))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildInsights() {
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
          const Text('📊 分析洞察', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ..._result!.insights.map((insight) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_getInsightIcon(insight.type), style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(insight.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(insight.description, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
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
          const Text('💡 健康建议', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ..._result!.suggestions.map((s) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_getCategoryIcon(s.category), style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(child: Text(s.suggestion, style: const TextStyle(fontSize: 13))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        border: Border.all(color: Colors.amber.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        '⚠️ 以上分析仅供参考，不能替代专业医疗诊断。如有不适，请及时就医。',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.amber, fontSize: 12),
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
            _buildNavItem('🏠', '首页', false, () => Navigator.pop(context)),
            _buildNavItem('📊', '数据', false, const DataPage()),
            _buildNavItem('🤖', '分析', true),
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
