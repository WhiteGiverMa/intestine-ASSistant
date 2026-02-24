import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/theme_colors.dart';
import '../theme/theme_decorations.dart';
import '../widgets/app_header.dart';
import '../services/local_db_service.dart';

const Map<int, String> kStoolTypeLabels = {
  1: '坚果状',
  2: '香肠状(块)',
  3: '香肠状(裂)',
  4: '香肠状(滑)',
  5: '软团状',
  6: '糊状',
  7: '水状',
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

const Map<int, String> kStoolTypeEmojis = {
  1: '🪨',
  2: '🥜',
  3: '🌭',
  4: '🍌',
  5: '🫘',
  6: '🥣',
  7: '💧',
};

class TestDataGeneratorPage extends StatefulWidget {
  const TestDataGeneratorPage({super.key});

  @override
  State<TestDataGeneratorPage> createState() => _TestDataGeneratorPageState();
}

class _TestDataGeneratorPageState extends State<TestDataGeneratorPage> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  int _minDailyCount = 1;
  int _maxDailyCount = 3;
  bool _isCustomMode = false;
  bool _isGenerating = false;

  final Set<int> _selectedStoolTypes = {1, 2, 3, 4, 5, 6, 7};
  final Set<String> _selectedColors = {
    'brown',
    'dark_brown',
    'light_brown',
    'green',
    'yellow',
    'black',
    'red',
  };
  int _minSmellLevel = 1;
  int _maxSmellLevel = 5;
  final Set<String> _selectedFeelings = {
    'smooth',
    'difficult',
    'painful',
    'urgent',
    'incomplete',
  };
  int _minDuration = 5;
  int _maxDuration = 20;

  final _random = Random();

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colors = themeProvider.colors;

    return Scaffold(
      body: Container(
        decoration: ThemeDecorations.backgroundGradient(
          context,
          mode: themeProvider.mode,
        ),
        child: SafeArea(
          child: Column(
            children: [
              const AppHeader(title: '测试数据生成器', showBackButton: true),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildDateRangeSection(colors),
                      const SizedBox(height: 16),
                      _buildDailyCountSection(colors),
                      const SizedBox(height: 16),
                      _buildModeToggle(colors),
                      const SizedBox(height: 16),
                      if (_isCustomMode) _buildCustomConfigSection(colors),
                      if (_isCustomMode) const SizedBox(height: 16),
                      _buildGenerateButton(colors),
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

  Widget _buildDateRangeSection(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: ThemeDecorations.card(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📅', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                '时间段选择',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildDateButton(
                  colors,
                  '开始日期',
                  _startDate,
                  () => _selectDate(true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDateButton(
                  colors,
                  '结束日期',
                  _endDate,
                  () => _selectDate(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '共 ${_endDate.difference(_startDate).inDays + 1} 天',
            style: TextStyle(fontSize: 12, color: colors.textHint),
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton(
    ThemeColors colors,
    String label,
    DateTime date,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: colors.divider),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 14, color: colors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_startDate.isAfter(_endDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _startDate = _endDate;
          }
        }
      });
    }
  }

  Widget _buildDailyCountSection(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: ThemeDecorations.card(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🔢', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                '每日排便次数',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildNumberInput(
                  colors,
                  '最少',
                  _minDailyCount,
                  (v) => setState(() {
                    _minDailyCount = v;
                    if (_minDailyCount > _maxDailyCount) {
                      _maxDailyCount = _minDailyCount;
                    }
                  }),
                  max: 10,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildNumberInput(
                  colors,
                  '最多',
                  _maxDailyCount,
                  (v) => setState(() {
                    _maxDailyCount = v;
                    if (_maxDailyCount < _minDailyCount) {
                      _minDailyCount = _maxDailyCount;
                    }
                  }),
                  max: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumberInput(
    ThemeColors colors,
    String label,
    int value,
    Function(int) onChanged, {
    int min = 0,
    int max = 100,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: colors.textSecondary),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              onPressed: value > min ? () => onChanged(value - 1) : null,
              icon: Icon(
                Icons.remove,
                color: value > min ? colors.primary : colors.textHint,
              ),
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            Expanded(
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
            ),
            IconButton(
              onPressed: value < max ? () => onChanged(value + 1) : null,
              icon: Icon(
                Icons.add,
                color: value < max ? colors.primary : colors.textHint,
              ),
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModeToggle(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: ThemeDecorations.card(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🎲', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                '生成模式',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isCustomMode = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color:
                          !_isCustomMode ? colors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: !_isCustomMode ? colors.primary : colors.divider,
                      ),
                    ),
                    child: Text(
                      '完全随机',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color:
                            !_isCustomMode
                                ? colors.textOnPrimary
                                : colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isCustomMode = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color:
                          _isCustomMode ? colors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _isCustomMode ? colors.primary : colors.divider,
                      ),
                    ),
                    child: Text(
                      '自定义随机',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color:
                            _isCustomMode
                                ? colors.textOnPrimary
                                : colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _isCustomMode ? '自定义各项数据的随机范围' : '所有数据完全随机生成',
            style: TextStyle(fontSize: 12, color: colors.textHint),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomConfigSection(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: ThemeDecorations.card(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⚙️', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                '自定义随机设置',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _buildStoolTypeSelector(colors),
          const SizedBox(height: 16),
          _buildColorSelector(colors),
          const SizedBox(height: 16),
          _buildSmellLevelSelector(colors),
          const SizedBox(height: 16),
          _buildFeelingSelector(colors),
          const SizedBox(height: 16),
          _buildDurationSelector(colors),
        ],
      ),
    );
  }

  Widget _buildStoolTypeSelector(ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '便便类型 (布里斯托分类)',
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
              kStoolTypeLabels.entries.map((e) {
                final isSelected = _selectedStoolTypes.contains(e.key);
                return GestureDetector(
                  onTap:
                      () => setState(() {
                        if (isSelected) {
                          if (_selectedStoolTypes.length > 1) {
                            _selectedStoolTypes.remove(e.key);
                          }
                        } else {
                          _selectedStoolTypes.add(e.key);
                        }
                      }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? colors.primary.withValues(alpha: 0.1)
                              : colors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? colors.primary : colors.divider,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          kStoolTypeEmojis[e.key] ?? '',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${e.key}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                            color:
                                isSelected
                                    ? colors.primary
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

  Widget _buildColorSelector(ThemeColors colors) {
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
              kColorLabels.entries.map((e) {
                final isSelected = _selectedColors.contains(e.key);
                return GestureDetector(
                  onTap:
                      () => setState(() {
                        if (isSelected) {
                          if (_selectedColors.length > 1) {
                            _selectedColors.remove(e.key);
                          }
                        } else {
                          _selectedColors.add(e.key);
                        }
                      }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? colors.primary.withValues(alpha: 0.1)
                              : colors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? colors.primary : colors.divider,
                      ),
                    ),
                    child: Text(
                      e.value,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color:
                            isSelected ? colors.primary : colors.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildSmellLevelSelector(ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '气味等级 (1-5)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              '范围:',
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
            const SizedBox(width: 12),
            _buildSmallNumberButton(
              colors,
              _minSmellLevel,
              () => setState(() {
                if (_minSmellLevel > 1) {
                  _minSmellLevel--;
                  if (_minSmellLevel > _maxSmellLevel) {
                    _maxSmellLevel = _minSmellLevel;
                  }
                }
              }),
              Icons.remove,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '$_minSmellLevel',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
            ),
            _buildSmallNumberButton(
              colors,
              _minSmellLevel,
              () => setState(() {
                if (_minSmellLevel < 5 && _minSmellLevel < _maxSmellLevel) {
                  _minSmellLevel++;
                }
              }),
              Icons.add,
            ),
            const SizedBox(width: 16),
            Text(
              '~',
              style: TextStyle(fontSize: 14, color: colors.textSecondary),
            ),
            const SizedBox(width: 16),
            _buildSmallNumberButton(
              colors,
              _maxSmellLevel,
              () => setState(() {
                if (_maxSmellLevel > _minSmellLevel) {
                  _maxSmellLevel--;
                }
              }),
              Icons.remove,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '$_maxSmellLevel',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
            ),
            _buildSmallNumberButton(
              colors,
              _maxSmellLevel,
              () => setState(() {
                if (_maxSmellLevel < 5) {
                  _maxSmellLevel++;
                  if (_maxSmellLevel < _minSmellLevel) {
                    _minSmellLevel = _maxSmellLevel;
                  }
                }
              }),
              Icons.add,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSmallNumberButton(
    ThemeColors colors,
    int value,
    VoidCallback onTap,
    IconData icon,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: colors.divider),
        ),
        child: Icon(icon, size: 14, color: colors.textSecondary),
      ),
    );
  }

  Widget _buildFeelingSelector(ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '感受',
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
              kFeelingLabels.entries.map((e) {
                final isSelected = _selectedFeelings.contains(e.key);
                return GestureDetector(
                  onTap:
                      () => setState(() {
                        if (isSelected) {
                          if (_selectedFeelings.length > 1) {
                            _selectedFeelings.remove(e.key);
                          }
                        } else {
                          _selectedFeelings.add(e.key);
                        }
                      }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? colors.primary.withValues(alpha: 0.1)
                              : colors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? colors.primary : colors.divider,
                      ),
                    ),
                    child: Text(
                      e.value,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color:
                            isSelected ? colors.primary : colors.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildDurationSelector(ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '时长 (分钟)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(
                    '最少:',
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                  const SizedBox(width: 8),
                  _buildSmallNumberButton(
                    colors,
                    _minDuration,
                    () => setState(() {
                      if (_minDuration > 1) {
                        _minDuration--;
                        if (_minDuration > _maxDuration) {
                          _maxDuration = _minDuration;
                        }
                      }
                    }),
                    Icons.remove,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '$_minDuration',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  _buildSmallNumberButton(
                    colors,
                    _minDuration,
                    () => setState(() {
                      if (_minDuration < 60 && _minDuration < _maxDuration) {
                        _minDuration++;
                      }
                    }),
                    Icons.add,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Row(
                children: [
                  Text(
                    '最多:',
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                  const SizedBox(width: 8),
                  _buildSmallNumberButton(
                    colors,
                    _maxDuration,
                    () => setState(() {
                      if (_maxDuration > _minDuration) {
                        _maxDuration--;
                      }
                    }),
                    Icons.remove,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '$_maxDuration',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  _buildSmallNumberButton(
                    colors,
                    _maxDuration,
                    () => setState(() {
                      if (_maxDuration < 60) {
                        _maxDuration++;
                        if (_maxDuration < _minDuration) {
                          _minDuration = _maxDuration;
                        }
                      }
                    }),
                    Icons.add,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGenerateButton(ThemeColors colors) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isGenerating ? null : _showGenerateConfirm,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.textOnPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child:
            _isGenerating
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                : const Text(
                  '🎲 生成随机数据',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
      ),
    );
  }

  int _estimateRecordCount() {
    final days = _endDate.difference(_startDate).inDays + 1;
    final avgCount = (_minDailyCount + _maxDailyCount) / 2;
    return (days * avgCount).round();
  }

  void _showGenerateConfirm() {
    final colors = context.read<ThemeProvider>().colors;
    final estimatedCount = _estimateRecordCount();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('确认生成'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('即将在以下时间段生成随机数据：'),
                const SizedBox(height: 8),
                Text(
                  '${_startDate.toString().split(' ')[0]} ~ ${_endDate.toString().split(' ')[0]}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('每日次数：$_minDailyCount ~ $_maxDailyCount 次'),
                const SizedBox(height: 8),
                Text(
                  '预估记录数：约 $estimatedCount 条',
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  '取消',
                  style: TextStyle(color: colors.textSecondary),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _generateData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                ),
                child: Text(
                  '确认生成',
                  style: TextStyle(color: colors.textOnPrimary),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _generateData() async {
    setState(() => _isGenerating = true);

    try {
      int generatedCount = 0;
      final stoolTypes =
          _isCustomMode ? _selectedStoolTypes.toList() : [1, 2, 3, 4, 5, 6, 7];
      final colorOptions =
          _isCustomMode ? _selectedColors.toList() : kColorLabels.keys.toList();
      final minSmell = _isCustomMode ? _minSmellLevel : 1;
      final maxSmell = _isCustomMode ? _maxSmellLevel : 5;
      final feelings =
          _isCustomMode
              ? _selectedFeelings.toList()
              : kFeelingLabels.keys.toList();
      final minDur = _isCustomMode ? _minDuration : 5;
      final maxDur = _isCustomMode ? _maxDuration : 20;

      for (
        var d = _startDate;
        !d.isAfter(_endDate);
        d = d.add(const Duration(days: 1))
      ) {
        final dailyCount =
            _minDailyCount +
            _random.nextInt(_maxDailyCount - _minDailyCount + 1);

        for (var i = 0; i < dailyCount; i++) {
          final hour = 6 + _random.nextInt(18);
          final minute = _random.nextInt(60);
          final recordTime =
              '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

          await LocalDbService.createRecord(
            recordDate:
                '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
            recordTime: recordTime,
            durationMinutes: minDur + _random.nextInt(maxDur - minDur + 1),
            stoolType: stoolTypes[_random.nextInt(stoolTypes.length)],
            color: colorOptions[_random.nextInt(colorOptions.length)],
            smellLevel: minSmell + _random.nextInt(maxSmell - minSmell + 1),
            feeling: feelings[_random.nextInt(feelings.length)],
          );
          generatedCount++;
        }
      }

      _showSuccess('成功生成 $generatedCount 条记录');
    } catch (e) {
      _showError('生成失败：$e');
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  void _showSuccess(String message) {
    final colors = context.read<ThemeProvider>().colors;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: colors.success),
    );
  }

  void _showError(String message) {
    final colors = context.read<ThemeProvider>().colors;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: colors.error),
    );
  }
}
