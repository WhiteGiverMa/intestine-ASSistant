import 'package:flutter/material.dart';
import '../theme/theme_colors.dart';

class StoolTypeSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final ThemeColors colors;

  const StoolTypeSelector({
    super.key,
    required this.value,
    required this.onChanged,
    required this.colors,
  });

  static const _bristolTypes = [
    {'emoji': '🪨', 'label': '硬块', 'status': '便秘'},
    {'emoji': '🥜', 'label': '结块', 'status': '轻便秘'},
    {'emoji': '🌭', 'label': '裂纹', 'status': '正常'},
    {'emoji': '🍌', 'label': '光滑', 'status': '理想'},
    {'emoji': '🫘', 'label': '柔软断块', 'status': '缺纤维'},
    {'emoji': '🥣', 'label': '糊状', 'status': '轻腹泻'},
    {'emoji': '💧', 'label': '液体', 'status': '腹泻'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '粪便形态（布里斯托分类）',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            int crossAxisCount;
            double spacing;

            if (width >= 600) {
              crossAxisCount = 7;
              spacing = 8;
            } else if (width >= 450) {
              crossAxisCount = 4;
              spacing = 8;
            } else if (width >= 360) {
              crossAxisCount = 3;
              spacing = 6;
            } else {
              crossAxisCount = 2;
              spacing = 6;
            }

            return _buildGridLayout(
              crossAxisCount: crossAxisCount,
              spacing: spacing,
            );
          },
        ),
      ],
    );
  }

  Widget _buildGridLayout({
    required int crossAxisCount,
    required double spacing,
  }) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: spacing,
      crossAxisSpacing: spacing,
      childAspectRatio: 0.85,
      children: List.generate(7, (index) => _buildTypeCard(index)),
    );
  }

  Widget _buildTypeCard(int index) {
    final type = index + 1;
    final isSelected = value == type;
    final bristol = _bristolTypes[index];
    final status = bristol['status'] as String;

    Color statusColor;
    if (status == '理想') {
      statusColor = colors.success;
    } else if (status == '正常') {
      statusColor = colors.success.withValues(alpha: 0.8);
    } else if (status.contains('便秘') || status.contains('腹泻')) {
      statusColor = colors.error;
    } else {
      statusColor = colors.warning;
    }

    return GestureDetector(
      onTap: () => onChanged(type),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : colors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border:
              isSelected ? Border.all(color: statusColor, width: 2.5) : null,
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                  : [
                    BoxShadow(
                      color: colors.shadow.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 类型编号 + 标签（重点突出）
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? colors.textOnPrimary.withValues(alpha: 0.2)
                            : colors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$type',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color:
                            isSelected ? colors.textOnPrimary : colors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  bristol['label'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color:
                        isSelected ? colors.textOnPrimary : colors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Emoji 缩小
            Text(
              bristol['emoji'] as String,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 6),
            // 状态标签
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: isSelected ? 0.25 : 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? colors.textOnPrimary : statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ColorSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final ThemeColors colors;

  const ColorSelector({
    super.key,
    required this.value,
    required this.onChanged,
    required this.colors,
  });

  static const _options = [
    {'value': 'brown', 'label': '棕色', 'color': Color(0xFF8B4513)},
    {'value': 'dark_brown', 'label': '深棕', 'color': Color(0xFF5D4037)},
    {'value': 'light_brown', 'label': '浅棕', 'color': Color(0xFFA1887F)},
    {'value': 'green', 'label': '绿色', 'color': Color(0xFF4CAF50)},
    {'value': 'yellow', 'label': '黄色', 'color': Color(0xFFFFEB3B)},
    {'value': 'black', 'label': '黑色', 'color': Color(0xFF212121)},
    {'value': 'red', 'label': '红色', 'color': Color(0xFFF44336)},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '颜色',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              _options.map((c) {
                final isSelected = value == c['value'];
                return GestureDetector(
                  onTap: () => onChanged(c['value'] as String),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceVariant,
                      borderRadius: BorderRadius.circular(16),
                      border:
                          isSelected
                              ? Border.all(color: colors.primary, width: 2)
                              : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: c['color'] as Color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          c['label'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }
}

class SmellSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final ThemeColors colors;

  const SmellSelector({
    super.key,
    required this.value,
    required this.onChanged,
    required this.colors,
  });

  static const _levels = ['无', '轻微', '一般', '较重', '严重'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '气味',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            final level = index + 1;
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(level),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color:
                        value == level ? colors.primary : colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _levels[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          value == level
                              ? colors.textOnPrimary
                              : colors.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class FeelingSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final ThemeColors colors;

  const FeelingSelector({
    super.key,
    required this.value,
    required this.onChanged,
    required this.colors,
  });

  static const _feelings = [
    {'value': 'smooth', 'label': '顺畅', 'emoji': '😊'},
    {'value': 'difficult', 'label': '困难', 'emoji': '😣'},
    {'value': 'painful', 'label': '疼痛', 'emoji': '😫'},
    {'value': 'urgent', 'label': '急迫', 'emoji': '😰'},
    {'value': 'incomplete', 'label': '不尽', 'emoji': '😕'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '排便感受',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              _feelings.map((f) {
                final isSelected = value == f['value'];
                return GestureDetector(
                  onTap: () => onChanged(f['value'] as String),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? colors.primary : colors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          f['emoji'] as String,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          f['label'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                isSelected
                                    ? colors.textOnPrimary
                                    : colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }
}

class SymptomsSelector extends StatelessWidget {
  final List<String> value;
  final ValueChanged<List<String>> onChanged;
  final ThemeColors colors;

  const SymptomsSelector({
    super.key,
    required this.value,
    required this.onChanged,
    required this.colors,
  });

  static const _allSymptoms = [
    '腹痛',
    '腹胀',
    '恶心',
    '便血',
    '粘液',
    '排气增多/胀气',
    '肛门发烫/疼痛',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '伴随症状',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              _allSymptoms.map((s) {
                final isSelected = value.contains(s);
                return GestureDetector(
                  onTap: () {
                    final newList = List<String>.from(value);
                    if (isSelected) {
                      newList.remove(s);
                    } else {
                      newList.add(s);
                    }
                    onChanged(newList);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? colors.primary : colors.surfaceVariant,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      s,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isSelected
                                ? colors.textOnPrimary
                                : colors.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }
}
