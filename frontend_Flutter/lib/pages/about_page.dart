import 'package:flutter/material.dart';

const String appVersion = '0.2.0';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

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
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildAppInfo(),
                      const SizedBox(height: 16),
                      _buildVersionCard(),
                      const SizedBox(height: 16),
                      _buildDeveloperCard(),
                      const SizedBox(height: 16),
                      _buildPoweredByCard(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
            child: const Text(
              '←',
              style: TextStyle(fontSize: 20, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            '关于',
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

  Widget _buildAppInfo() {
    return Column(
      children: [
        const SizedBox(height: 24),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF2E7D32),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              '🚽',
              style: TextStyle(fontSize: 40),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Intestine ASSistant',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '智能排便健康助手',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildVersionCard() {
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
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text('📱', style: TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '版本号',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '当前版本',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(
            'v$appVersion',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperCard() {
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
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text('👨‍💻', style: TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '开发者',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '项目作者',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const Text(
            '马戈',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoweredByCard() {
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
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text('🤖', style: TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Powered by',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPoweredByItem('GLM-5', '智谱AI大语言模型'),
          const SizedBox(height: 12),
          _buildPoweredByItem('DeepSeek v3.2', '深度求索AI模型'),
        ],
      ),
    );
  }

  Widget _buildPoweredByItem(String name, String description) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF2E7D32),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
