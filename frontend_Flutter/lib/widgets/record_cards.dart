import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../theme/theme_colors.dart';
import '../theme/theme_decorations.dart';

const Map<int, String> kStoolTypeEmojis = {
  1: '🪨',
  2: '🥜',
  3: '🌭',
  4: '🍌',
  5: '🫘',
  6: '🥣',
  7: '💧',
};

const Map<String, String> kColorLabels = {
  'brown': '棕色',
  'dark_brown': '深棕',
  'light_brown': '浅棕',
  'green': '绿色',
  'yellow': '黄色',
  'black': '黑色',
  'red': '红色',
};

const Map<String, String> kFeelingLabels = {
  'smooth': '顺畅',
  'difficult': '困难',
  'painful': '疼痛',
  'urgent': '急迫',
  'incomplete': '不尽',
};

class RecordCard extends StatelessWidget {
  final BowelRecord record;
  final ThemeColors colors;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const RecordCard({
    super.key,
    required this.record,
    required this.colors,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: ThemeDecorations.card(context),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  kStoolTypeEmojis[record.stoolType] ?? '📝',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        record.recordDate,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: colors.textPrimary,
                        ),
                      ),
                      if (record.recordTime != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          record.recordTime!,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (record.lid != null)
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: record.lid!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('LID已复制'),
                                duration: const Duration(seconds: 1),
                                backgroundColor: colors.primary,
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: colors.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  record.lid!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colors.primary,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.copy,
                                  size: 12,
                                  color: colors.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (record.stoolType != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: colors.surfaceVariant,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '类型${record.stoolType}',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                      if (record.durationMinutes != null)
                        Text(
                          '${record.durationMinutes}分钟',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                  if (record.feeling != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        kFeelingLabels[record.feeling] ?? record.feeling!,
                        style: TextStyle(fontSize: 12, color: colors.textHint),
                      ),
                    ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.delete_outline,
                  color: colors.textHint,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NoBowelCard extends StatelessWidget {
  final BowelRecord record;
  final ThemeColors colors;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const NoBowelCard({
    super.key,
    required this.record,
    required this.colors,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('⭕', style: TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.recordDate,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (record.lid != null)
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: record.lid!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('LID已复制'),
                                duration: const Duration(seconds: 1),
                                backgroundColor: colors.textSecondary,
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: colors.divider),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  record.lid!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.copy,
                                  size: 12,
                                  color: colors.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      Text(
                        '无排便',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.delete_outline,
                  color: colors.textHint,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RecordDetailSheet extends StatelessWidget {
  final BowelRecord record;
  final ThemeColors colors;
  final VoidCallback onDelete;

  const RecordDetailSheet({
    super.key,
    required this.record,
    required this.colors,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder:
          (context, scrollController) => Container(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        record.isNoBowel ? '无排便记录' : '记录详情',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onDelete();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: colors.error,
                        ),
                        child: const Text('删除'),
                      ),
                    ],
                  ),
                  Divider(color: colors.divider),
                  if (record.lid != null) _buildLidRow(record.lid!, context),
                  _buildDetailRow('📅 日期', record.recordDate),
                  if (!record.isNoBowel) ...[
                    if (record.recordTime != null)
                      _buildDetailRow('⏰ 时间', record.recordTime!),
                    if (record.durationMinutes != null)
                      _buildDetailRow('⏱️ 时长', '${record.durationMinutes} 分钟'),
                    if (record.stoolType != null)
                      _buildDetailRow(
                        '📊 粪便类型',
                        '${kStoolTypeEmojis[record.stoolType] ?? ''} 类型 ${record.stoolType}',
                      ),
                    if (record.color != null)
                      _buildDetailRow(
                        '🎨 颜色',
                        kColorLabels[record.color] ?? record.color!,
                      ),
                    if (record.smellLevel != null)
                      _buildDetailRow('👃 气味等级', '${record.smellLevel}/5'),
                    if (record.feeling != null)
                      _buildDetailRow(
                        '😊 感受',
                        kFeelingLabels[record.feeling] ?? record.feeling!,
                      ),
                    if (record.symptoms != null && record.symptoms!.isNotEmpty)
                      _buildDetailRow('🏥 伴随症状', record.symptoms!),
                    if (record.notes != null && record.notes!.isNotEmpty)
                      _buildDetailRow('📝 备注', record.notes!),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    '创建时间: ${record.createdAt}',
                    style: TextStyle(fontSize: 12, color: colors.textHint),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildLidRow(String lid, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '🏷️ LID',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Text(
                  lid,
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: lid));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('LID已复制'),
                        duration: const Duration(seconds: 1),
                        backgroundColor: colors.primary,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.copy, size: 14, color: colors.primary),
                        const SizedBox(width: 4),
                        Text(
                          '复制',
                          style: TextStyle(fontSize: 12, color: colors.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: colors.textPrimary)),
          ),
        ],
      ),
    );
  }

  static void show({
    required BuildContext context,
    required BowelRecord record,
    required ThemeColors colors,
    required VoidCallback onDelete,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: colors.divider),
      ),
      builder:
          (context) => RecordDetailSheet(
            record: record,
            colors: colors,
            onDelete: onDelete,
          ),
    );
  }
}
