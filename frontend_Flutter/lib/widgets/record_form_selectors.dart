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

  static const _emojis = ['🪨', '🥜', '🌭', '🍌', '🫘', '🥣', '💧'];

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
        const SizedBox(height: 8),
        Row(
          children: List.generate(7, (index) {
            final type = index + 1;
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(type),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color:
                        value == type ? colors.primary : colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _emojis[index],
                        style: const TextStyle(fontSize: 20),
                      ),
                      Text(
                        '$type',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              value == type
                                  ? colors.textOnPrimary
                                  : colors.textSecondary,
                        ),
                      ),
                    ],
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

  static const _allSymptoms = ['腹痛', '腹胀', '恶心', '便血', '粘液'];

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
