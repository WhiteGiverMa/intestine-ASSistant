import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/theme_colors.dart';
import 'date_input_field.dart';

class YearMonthPicker extends StatefulWidget {
  final int initialYear;
  final int initialMonth;
  final int? minYear;
  final int? maxYear;
  final Color? accentColor;

  const YearMonthPicker({
    super.key,
    required this.initialYear,
    required this.initialMonth,
    this.minYear,
    this.maxYear,
    this.accentColor,
  });

  static Future<DateTime?> show({
    required BuildContext context,
    required int initialYear,
    required int initialMonth,
    int? minYear,
    int? maxYear,
    Color? accentColor,
  }) async {
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => YearMonthPicker(
        initialYear: initialYear,
        initialMonth: initialMonth,
        minYear: minYear,
        maxYear: maxYear,
        accentColor: accentColor,
      ),
    );
  }

  @override
  State<YearMonthPicker> createState() => _YearMonthPickerState();
}

class _YearMonthPickerState extends State<YearMonthPicker> {
  static const int _defaultMinYear = 2012;
  static const int _defaultMaxYear = 2112;

  late int _selectedYear;
  late int _selectedMonth;
  late final int _minYear;
  late final int _maxYear;

  late final PageController _yearPageController;
  late final ScrollController _monthScrollController;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear;
    _selectedMonth = widget.initialMonth;
    _minYear = widget.minYear ?? _defaultMinYear;
    _maxYear = widget.maxYear ?? _defaultMaxYear;

    final initialPage = _selectedYear - _minYear;
    _yearPageController = PageController(initialPage: initialPage);
    _monthScrollController = ScrollController();
  }

  @override
  void dispose() {
    _yearPageController.dispose();
    _monthScrollController.dispose();
    super.dispose();
  }

  int get _yearCount => _maxYear - _minYear + 1;

  void _onYearPageChanged(int page) {
    setState(() {
      _selectedYear = _minYear + page;
    });
  }

  void _onYearChanged(int delta) {
    final newYear = (_selectedYear + delta).clamp(_minYear, _maxYear);
    if (newYear != _selectedYear) {
      setState(() {
        _selectedYear = newYear;
      });
      _yearPageController.animateToPage(
        newYear - _minYear,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onMonthSelected(int month) {
    setState(() {
      _selectedMonth = month;
    });
  }

  void _onConfirm() {
    Navigator.pop(context, DateTime(_selectedYear, _selectedMonth));
  }

  void _onCancel() {
    Navigator.pop(context);
  }

  void _onTodayPressed() {
    final now = DateTime.now();
    setState(() {
      _selectedYear = now.year.clamp(_minYear, _maxYear);
      _selectedMonth = now.month;
    });
    _yearPageController.animateToPage(
      _selectedYear - _minYear,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onInputChanged(DateTime date) {
    setState(() {
      _selectedYear = date.year.clamp(_minYear, _maxYear);
      _selectedMonth = date.month;
    });
    _yearPageController.animateToPage(
      _selectedYear - _minYear,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;
    final accentColor = widget.accentColor ?? colors.primary;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.textHint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _onCancel,
                child: Text(
                  '取消',
                  style: TextStyle(color: colors.textSecondary),
                ),
              ),
              Text(
                '选择年月',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: _onConfirm,
                child: Text('确定', style: TextStyle(color: accentColor)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildYearSelector(colors, accentColor),
          const SizedBox(height: 16),
          _buildMonthGrid(colors, accentColor),
          const SizedBox(height: 16),
          _buildInputSection(colors, accentColor),
          const SizedBox(height: 16),
          _buildTodayButton(colors, accentColor),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildYearSelector(ThemeColors colors, Color accentColor) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _selectedYear > _minYear
                ? () => _onYearChanged(-1)
                : null,
            color: accentColor,
          ),
          Expanded(
            child: PageView.builder(
              controller: _yearPageController,
              onPageChanged: _onYearPageChanged,
              itemCount: _yearCount,
              itemBuilder: (context, index) {
                final year = _minYear + index;
                final isSelected = year == _selectedYear;
                return Center(
                  child: Text(
                    '$year 年',
                    style: TextStyle(
                      fontSize: isSelected ? 24 : 20,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected ? accentColor : colors.textSecondary,
                    ),
                  ),
                );
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _selectedYear < _maxYear
                ? () => _onYearChanged(1)
                : null,
            color: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthGrid(ThemeColors colors, Color accentColor) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        final month = index + 1;
        final isSelected = month == _selectedMonth;
        return GestureDetector(
          onTap: () => _onMonthSelected(month),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? accentColor : colors.cardBackground,
              borderRadius: BorderRadius.circular(8),
              border: isSelected ? null : Border.all(color: colors.textHint),
            ),
            child: Center(
              child: Text(
                '$month月',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? colors.textOnPrimary : colors.textPrimary,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputSection(ThemeColors colors, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.textHint),
      ),
      child: Row(
        children: [
          Icon(Icons.edit, size: 16, color: colors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: DateInputField(
              initialDate: DateTime(_selectedYear, _selectedMonth),
              firstDate: DateTime(_minYear),
              lastDate: DateTime(_maxYear, 12, 31),
              accentColor: accentColor,
              showDay: false,
              showDatePicker: false,
              onChanged: _onInputChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayButton(ThemeColors colors, Color accentColor) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _onTodayPressed,
        icon: Icon(Icons.today, color: accentColor),
        label: Text('回到今天', style: TextStyle(color: accentColor)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: accentColor.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
