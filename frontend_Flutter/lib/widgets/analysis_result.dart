import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/theme_colors.dart';
import '../theme/theme_decorations.dart';

class AnalysisResultView extends StatelessWidget {
  final AnalysisResult result;
  final ThemeColors colors;

  const AnalysisResultView({
    super.key,
    required this.result,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        HealthScoreCard(score: result.healthScore, colors: colors),
        if (result.warnings.isNotEmpty) ...[
          const SizedBox(height: 16),
          WarningsCard(warnings: result.warnings, colors: colors),
        ],
        const SizedBox(height: 16),
        InsightsCard(insights: result.insights, colors: colors),
        const SizedBox(height: 16),
        SuggestionsCard(suggestions: result.suggestions, colors: colors),
        const SizedBox(height: 16),
        const DisclaimerCard(),
      ],
    );
  }
}

class HealthScoreCard extends StatelessWidget {
  final int score;
  final ThemeColors colors;

  const HealthScoreCard({super.key, required this.score, required this.colors});

  Color _getScoreColor() {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    if (score >= 40) return Colors.deepOrange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: ThemeDecorations.card(context),
      child: Column(
        children: [
          Text(
            '肠道健康评分',
            style: TextStyle(fontSize: 14, color: colors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            '$score',
            style: TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.bold,
              color: _getScoreColor(),
            ),
          ),
          Text('满分 100', style: TextStyle(color: colors.textSecondary)),
        ],
      ),
    );
  }
}

class WarningsCard extends StatelessWidget {
  final List<Warning> warnings;
  final ThemeColors colors;

  const WarningsCard({super.key, required this.warnings, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.errorBackground,
        border: Border.all(color: colors.error.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⚠️', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                '健康提醒',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...warnings.map(
            (w) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(color: colors.error)),
                  Expanded(
                    child: Text(
                      w.message,
                      style: TextStyle(color: colors.error),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InsightsCard extends StatelessWidget {
  final List<Insight> insights;
  final ThemeColors colors;

  const InsightsCard({super.key, required this.insights, required this.colors});

  String _getInsightIcon(String type) {
    switch (type) {
      case 'pattern':
        return '📊';
      case 'stool_type':
        return '💩';
      case 'frequency':
        return '📈';
      default:
        return '💡';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: ThemeDecorations.card(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📊 分析洞察',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...insights.map(
            (insight) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getInsightIcon(insight.type),
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          insight.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          insight.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SuggestionsCard extends StatelessWidget {
  final List<Suggestion> suggestions;
  final ThemeColors colors;

  const SuggestionsCard({
    super.key,
    required this.suggestions,
    required this.colors,
  });

  String _getCategoryIcon(String category) {
    switch (category) {
      case 'diet':
        return '🥗';
      case 'habit':
        return '🔄';
      case 'lifestyle':
        return '🏃';
      case 'health':
        return '💊';
      default:
        return '💡';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: ThemeDecorations.card(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💡 健康建议',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...suggestions.map(
            (s) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.primaryLight.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getCategoryIcon(s.category),
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      s.suggestion,
                      style: TextStyle(fontSize: 13, color: colors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DisclaimerCard extends StatelessWidget {
  const DisclaimerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        border: Border.all(color: Colors.amber.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '⚠️ 以上分析仅供参考，不能替代专业医疗诊断。如有不适，请及时就医。',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.amber[700], fontSize: 12),
      ),
    );
  }
}

class AnalysisPlaceholder extends StatelessWidget {
  final ThemeColors colors;

  const AnalysisPlaceholder({super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          const Text('🤖', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text('点击上方按钮开始 AI 分析', style: TextStyle(color: colors.textSecondary)),
          const SizedBox(height: 8),
          Text(
            '需要先记录排便数据才能进行分析',
            style: TextStyle(color: colors.textHint, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class AnalysisErrorCard extends StatelessWidget {
  final String error;
  final ThemeColors colors;
  final VoidCallback? onLogin;

  const AnalysisErrorCard({
    super.key,
    required this.error,
    required this.colors,
    this.onLogin,
  });

  bool _isAuthError() {
    return error.contains('登录') || error.contains('过期');
  }

  @override
  Widget build(BuildContext context) {
    final isAuthError = _isAuthError();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isAuthError ? Colors.orange.shade50 : colors.errorBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(isAuthError ? '🔒' : '❌', style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            error,
            style: TextStyle(
              color: isAuthError ? Colors.orange : colors.error,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          if (isAuthError && onLogin != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
}
