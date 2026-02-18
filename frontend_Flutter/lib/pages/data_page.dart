import 'package:flutter/material.dart';
import 'record_page.dart';
import 'stats_page.dart';
import 'data_management_page.dart';
import 'analysis_page.dart';
import 'settings_page.dart';

class DataPage extends StatefulWidget {
  const DataPage({super.key});

  @override
  State<DataPage> createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> {
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
      child: const Row(
        children: [
          Text(
            '数据管理',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcome() {
    return Column(
      children: [
        const Text('📊', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 16),
        const Text(
          '数据管理中心',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          '记录、查看和管理您的肠道健康数据',
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
            Expanded(child: _buildMenuItem('📝', '记录排便', '手动输入或计时记录', const RecordPage())),
            const SizedBox(width: 16),
            Expanded(child: _buildMenuItem('📊', '数据统计', '查看排便趋势和评分', const StatsPage())),
          ],
        ),
        const SizedBox(height: 16),
        _buildMenuItem('🗂️', '数据管理', '浏览、编辑和删除历史记录', const DataManagementPage(), fullWidth: true),
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
            _buildNavItem('📊', '数据', true),
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
