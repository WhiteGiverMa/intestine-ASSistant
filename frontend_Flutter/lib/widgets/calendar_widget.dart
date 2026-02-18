import 'package:flutter/material.dart';
import 'year_month_picker.dart';

class CalendarWidget extends StatefulWidget {
  final DateTime? selectedDate;
  final DateTime? startDate;
  final DateTime? endDate;
  final Map<String, int> dailyCounts;
  final List<String> noBowelDates;
  final Function(DateTime) onDateSelected;
  final Function(DateTime, DateTime)? onDateRangeSelected;
  final Function(DateTime)? onMarkNoBowel;
  final Function(DateTime)? onUnmarkNoBowel;
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
    this.onMarkNoBowel,
    this.onUnmarkNoBowel,
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
  bool _isSelectingRange = false;

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
    if (widget.selectedDate != null && widget.selectedDate != oldWidget.selectedDate) {
      _currentMonth = widget.selectedDate!;
    }
    if (widget.startDate != oldWidget.startDate || widget.endDate != oldWidget.endDate) {
      _rangeStart = widget.startDate;
      _rangeEnd = widget.endDate;
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
    final result = await YearMonthPicker.show(
      context: context,
      initialYear: _currentMonth.year,
      initialMonth: _currentMonth.month,
      minYear: widget.minYear,
      maxYear: widget.maxYear,
    );
    if (result != null) {
      setState(() {
        _currentMonth = result;
      });
    }
  }

  void _onDayTap(DateTime date) {
    if (_isSelectingRange) {
      if (_rangeStart == null) {
        setState(() {
          _rangeStart = date;
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
        _isSelectingRange = false;
        if (widget.onDateRangeSelected != null) {
          widget.onDateRangeSelected!(_rangeStart!, _rangeEnd!);
        }
      }
    } else {
      setState(() {
        _rangeStart = null;
        _rangeEnd = null;
      });
      widget.onDateSelected(date);
    }
  }

  void _onDayLongPress(DateTime date) {
    final dateStr = _formatDate(date);
    final isNoBowel = widget.noBowelDates.contains(dateStr);
    final hasRecords = widget.dailyCounts.containsKey(dateStr) && widget.dailyCounts[dateStr]! > 0;

    if (hasRecords) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('该日期已有排便记录，无法标注无排便')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatDateDisplay(date),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (isNoBowel)
              ListTile(
                leading: const Icon(Icons.remove_circle_outline, color: Colors.orange),
                title: const Text('取消"无排便"标注'),
                onTap: () {
                  Navigator.pop(context);
                  if (widget.onUnmarkNoBowel != null) {
                    widget.onUnmarkNoBowel!(date);
                  }
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.block, color: Colors.grey),
                title: const Text('标注为"无排便"'),
                subtitle: const Text('表示当天没有排便'),
                onTap: () {
                  Navigator.pop(context);
                  if (widget.onMarkNoBowel != null) {
                    widget.onMarkNoBowel!(date);
                  }
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDateDisplay(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }

  bool _isInRange(DateTime date) {
    if (_rangeStart == null || _rangeEnd == null) return false;
    return (date.isAfter(_rangeStart!) || date.isAtSameMomentAs(_rangeStart!)) &&
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

  @override
  Widget build(BuildContext context) {
    return Container(
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
          _buildHeader(),
          if (widget.isExpanded) ...[
            _buildWeekdayHeaders(),
            _buildCalendarGrid(),
            if (widget.onDateRangeSelected != null) _buildRangeModeToggle(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
        borderRadius: widget.isExpanded
            ? const BorderRadius.vertical(top: Radius.circular(16))
            : BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Color(0xFF2E7D32)),
            onPressed: widget.isExpanded ? _previousMonth : null,
          ),
          GestureDetector(
            onTap: _showYearMonthPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_currentMonth.year}年${_currentMonth.month}月',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_drop_down,
                    color: Color(0xFF2E7D32),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Color(0xFF2E7D32)),
                onPressed: widget.isExpanded ? _nextMonth : null,
              ),
              if (widget.onExpandToggle != null)
                IconButton(
                  icon: Icon(
                    widget.isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: const Color(0xFF2E7D32),
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

  Widget _buildWeekdayHeaders() {
    const weekdays = ['日', '一', '二', '三', '四', '五', '六'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: weekdays.map((day) {
          return Expanded(
            child: Center(
              child: Text(
                day,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final startingWeekday = firstDayOfMonth.weekday % 7;
    final totalDays = lastDayOfMonth.day;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    List<Widget> dayWidgets = [];

    for (int i = 0; i < startingWeekday; i++) {
      dayWidgets.add(const SizedBox());
    }

    for (int day = 1; day <= totalDays; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final dateStr = _formatDate(date);
      final count = widget.dailyCounts[dateStr] ?? -1;
      final isNoBowel = widget.noBowelDates.contains(dateStr);
      final isToday = date.isAtSameMomentAs(todayDate);
      final isSelected = widget.selectedDate != null &&
          date.year == widget.selectedDate!.year &&
          date.month == widget.selectedDate!.month &&
          date.day == widget.selectedDate!.day;
      final isInRange = _isInRange(date);
      final isRangeStart = _isRangeStart(date);
      final isRangeEnd = _isRangeEnd(date);

      dayWidgets.add(_buildDayCell(
        date: date,
        day: day,
        count: count,
        isNoBowel: isNoBowel,
        isToday: isToday,
        isSelected: isSelected,
        isInRange: isInRange,
        isRangeStart: isRangeStart,
        isRangeEnd: isRangeEnd,
      ));
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
  }) {
    Color? bgColor;
    Color textColor = Colors.black87;

    if (isRangeStart || isRangeEnd) {
      bgColor = const Color(0xFF2E7D32);
      textColor = Colors.white;
    } else if (isInRange) {
      bgColor = const Color(0xFF2E7D32).withValues(alpha: 0.2);
    } else if (isSelected) {
      bgColor = const Color(0xFF2E7D32);
      textColor = Colors.white;
    } else if (isToday) {
      bgColor = const Color(0xFF2E7D32).withValues(alpha: 0.1);
    }

    return GestureDetector(
      onTap: () => _onDayTap(date),
      onLongPress: () => _onDayLongPress(date),
      child: Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: isToday && !isSelected && !isRangeStart && !isRangeEnd
              ? Border.all(color: const Color(0xFF2E7D32), width: 1)
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
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0),
                decoration: BoxDecoration(
                  color: isSelected || isRangeStart || isRangeEnd || isInRange
                      ? Colors.white.withValues(alpha: 0.3)
                      : const Color(0xFF2E7D32).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isSelected || isRangeStart || isRangeEnd
                        ? Colors.white
                        : const Color(0xFF2E7D32),
                  ),
                ),
              )
            else if (isNoBowel)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0),
                decoration: BoxDecoration(
                  color: isSelected || isRangeStart || isRangeEnd
                      ? Colors.white.withValues(alpha: 0.3)
                      : Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  '0',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isSelected || isRangeStart || isRangeEnd
                        ? Colors.white
                        : Colors.grey,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRangeModeToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isSelectingRange = !_isSelectingRange;
                  if (!_isSelectingRange) {
                    _rangeStart = null;
                    _rangeEnd = null;
                  }
                });
              },
              icon: Icon(
                _isSelectingRange ? Icons.close : Icons.date_range,
                size: 16,
              ),
              label: Text(
                _isSelectingRange ? '取消选择' : '选择日期范围',
                style: const TextStyle(fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isSelectingRange ? Colors.grey : const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
