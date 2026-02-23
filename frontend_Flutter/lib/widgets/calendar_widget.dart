import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/theme_colors.dart';
import 'year_month_picker.dart';

class CalendarWidget extends StatefulWidget {
  final DateTime? selectedDate;
  final DateTime? startDate;
  final DateTime? endDate;
  final Map<String, int> dailyCounts;
  final List<String> noBowelDates;
  final Function(DateTime) onDateSelected;
  final Function(DateTime, DateTime)? onDateRangeSelected;
  final Function(DateTime)? onDateClick;
  final bool isExpanded;
  final VoidCallback? onExpandToggle;
  final int? minYear;
  final int? maxYear;

  const CalendarWidget({
    super.key,
    this.selectedDate,
    this.startDate,
    this.endDate,
    this.dailyCounts = const {},
    this.noBowelDates = const [],
    required this.onDateSelected,
    this.onDateRangeSelected,
    this.onDateClick,
    this.isExpanded = true,
    this.onExpandToggle,
    this.minYear,
    this.maxYear,
  });

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  late DateTime _currentMonth;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  @override
  void initState() {
    super.initState();
    _currentMonth = widget.selectedDate ?? DateTime.now();
    if (widget.startDate != null && widget.endDate != null) {
      _rangeStart = widget.startDate;
      _rangeEnd = widget.endDate;
    }
  }

  @override
  void didUpdateWidget(CalendarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != null &&
        widget.selectedDate != oldWidget.selectedDate) {
      _currentMonth = widget.selectedDate!;
    }
    if (widget.startDate != oldWidget.startDate ||
        widget.endDate != oldWidget.endDate) {
      _rangeStart = widget.startDate;
      _rangeEnd = widget.endDate;
      if (widget.endDate != null && oldWidget.endDate == null) {
        _currentMonth = DateTime(widget.endDate!.year, widget.endDate!.month);
      }
    }
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  Future<void> _showYearMonthPicker() async {
    final colors = context.read<ThemeProvider>().colors;
    final result = await YearMonthPicker.show(
      context: context,
      initialYear: _currentMonth.year,
      initialMonth: _currentMonth.month,
      minYear: widget.minYear,
      maxYear: widget.maxYear,
      accentColor: colors.primary,
    );
    if (result != null) {
      setState(() {
        _currentMonth = result;
      });
    }
  }

  void _onDayTap(DateTime date) {
    widget.onDateClick?.call(date);

    if (widget.onDateRangeSelected != null) {
      if (_rangeStart == null) {
        setState(() {
          _rangeStart = date;
          _rangeEnd = null;
        });
      } else if (_rangeEnd == null) {
        if (date.isBefore(_rangeStart!)) {
          setState(() {
            _rangeEnd = _rangeStart;
            _rangeStart = date;
          });
        } else {
          setState(() {
            _rangeEnd = date;
          });
        }
        widget.onDateRangeSelected!(_rangeStart!, _rangeEnd!);
      } else {
        setState(() {
          _rangeStart = date;
          _rangeEnd = null;
        });
      }
    } else {
      widget.onDateSelected(date);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  bool _isInRange(DateTime date) {
    if (_rangeStart == null || _rangeEnd == null) return false;
    return (date.isAfter(_rangeStart!) ||
            date.isAtSameMomentAs(_rangeStart!)) &&
        (date.isBefore(_rangeEnd!) || date.isAtSameMomentAs(_rangeEnd!));
  }

  bool _isRangeStart(DateTime date) {
    if (_rangeStart == null) return false;
    return date.year == _rangeStart!.year &&
        date.month == _rangeStart!.month &&
        date.day == _rangeStart!.day;
  }

  bool _isRangeEnd(DateTime date) {
    if (_rangeEnd == null) return false;
    return date.year == _rangeEnd!.year &&
        date.month == _rangeEnd!.month &&
        date.day == _rangeEnd!.day;
  }

  bool _isPendingStart(DateTime date) {
    if (widget.endDate != null || widget.startDate == null) return false;
    return date.year == widget.startDate!.year &&
        date.month == widget.startDate!.month &&
        date.day == widget.startDate!.day;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(colors),
          if (widget.isExpanded) ...[
            _buildWeekdayHeaders(colors),
            _buildCalendarGrid(colors),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.1),
        borderRadius:
            widget.isExpanded
                ? const BorderRadius.vertical(top: Radius.circular(16))
                : BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left, color: colors.primary),
            onPressed: widget.isExpanded ? _previousMonth : null,
          ),
          GestureDetector(
            onTap: _showYearMonthPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_currentMonth.year}年${_currentMonth.month}月',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down, color: colors.primary, size: 20),
                ],
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_right, color: colors.primary),
                onPressed: widget.isExpanded ? _nextMonth : null,
              ),
              if (widget.onExpandToggle != null)
                IconButton(
                  icon: Icon(
                    widget.isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: colors.primary,
                  ),
                  onPressed: widget.onExpandToggle,
                  tooltip: widget.isExpanded ? '收起' : '展开',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeaders(ThemeColors colors) {
    const weekdays = ['日', '一', '二', '三', '四', '五', '六'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children:
            weekdays.map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid(ThemeColors colors) {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month);
    final lastDayOfMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    );
    final startingWeekday = firstDayOfMonth.weekday % 7;
    final totalDays = lastDayOfMonth.day;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    final List<Widget> dayWidgets = [];

    for (int i = 0; i < startingWeekday; i++) {
      dayWidgets.add(const SizedBox());
    }

    for (int day = 1; day <= totalDays; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final dateStr = _formatDate(date);
      final count = widget.dailyCounts[dateStr] ?? -1;
      final isNoBowel = widget.noBowelDates.contains(dateStr);
      final isToday = date.isAtSameMomentAs(todayDate);
      final isSelected =
          widget.selectedDate != null &&
          date.year == widget.selectedDate!.year &&
          date.month == widget.selectedDate!.month &&
          date.day == widget.selectedDate!.day;
      final isInRange = _isInRange(date);
      final isRangeStart = _isRangeStart(date);
      final isRangeEnd = _isRangeEnd(date);
      final isPendingStart = _isPendingStart(date);

      dayWidgets.add(
        _buildDayCell(
          date: date,
          day: day,
          count: count,
          isNoBowel: isNoBowel,
          isToday: isToday,
          isSelected: isSelected,
          isInRange: isInRange,
          isRangeStart: isRangeStart,
          isRangeEnd: isRangeEnd,
          isPendingStart: isPendingStart,
          colors: colors,
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      childAspectRatio: 1.1,
      children: dayWidgets,
    );
  }

  Widget _buildDayCell({
    required DateTime date,
    required int day,
    required int count,
    required bool isNoBowel,
    required bool isToday,
    required bool isSelected,
    required bool isInRange,
    required bool isRangeStart,
    required bool isRangeEnd,
    required bool isPendingStart,
    required ThemeColors colors,
  }) {
    Color? bgColor;
    Color textColor = colors.textPrimary;

    if (isRangeStart || isRangeEnd) {
      bgColor = colors.primary;
      textColor = colors.textOnPrimary;
    } else if (isPendingStart) {
      bgColor = colors.primary.withValues(alpha: 0.5);
      textColor = colors.textOnPrimary;
    } else if (isInRange) {
      bgColor = colors.primary.withValues(alpha: 0.2);
    } else if (isSelected) {
      bgColor = colors.primary;
      textColor = colors.textOnPrimary;
    } else if (isToday) {
      bgColor = colors.primary.withValues(alpha: 0.1);
    }

    return GestureDetector(
      onTap: () => _onDayTap(date),
      child: Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border:
              isToday &&
                      !isSelected &&
                      !isRangeStart &&
                      !isRangeEnd &&
                      !isPendingStart
                  ? Border.all(color: colors.primary)
                  : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontSize: 12,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: textColor,
              ),
            ),
            const SizedBox(height: 1),
            if (count > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color:
                      isSelected ||
                              isRangeStart ||
                              isRangeEnd ||
                              isInRange ||
                              isPendingStart
                          ? colors.textOnPrimary.withValues(alpha: 0.3)
                          : colors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color:
                        isSelected ||
                                isRangeStart ||
                                isRangeEnd ||
                                isPendingStart
                            ? colors.textOnPrimary
                            : colors.primary,
                  ),
                ),
              )
            else if (isNoBowel)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color:
                      isSelected || isRangeStart || isRangeEnd || isPendingStart
                          ? colors.textOnPrimary.withValues(alpha: 0.3)
                          : colors.textHint.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  '0',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color:
                        isSelected ||
                                isRangeStart ||
                                isRangeEnd ||
                                isPendingStart
                            ? colors.textOnPrimary
                            : colors.textHint,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
