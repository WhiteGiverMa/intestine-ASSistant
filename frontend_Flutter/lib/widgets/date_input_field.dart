import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DateInputField extends StatefulWidget {
  final DateTime initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final ValueChanged<DateTime>? onChanged;
  final String? label;
  final Color? accentColor;
  final bool showDay;
  final bool showDatePicker;

  const DateInputField({
    super.key,
    required this.initialDate,
    this.firstDate,
    this.lastDate,
    this.onChanged,
    this.label,
    this.accentColor,
    this.showDay = true,
    this.showDatePicker = true,
  });

  @override
  State<DateInputField> createState() => _DateInputFieldState();
}

class _DateInputFieldState extends State<DateInputField> {
  late final TextEditingController _yearController;
  late final TextEditingController _monthController;
  late final TextEditingController _dayController;

  late final FocusNode _yearFocus;
  late final FocusNode _monthFocus;
  late final FocusNode _dayFocus;

  static const int _minYear = 2012;
  static const int _maxYear = 2112;

  late DateTime _currentDate;
  late final Color _accentColor;

  @override
  void initState() {
    super.initState();
    _currentDate = widget.initialDate;
    _accentColor = widget.accentColor ?? const Color(0xFF2E7D32);

    _yearController = TextEditingController(text: _currentDate.year.toString());
    _monthController = TextEditingController(
      text: _currentDate.month.toString().padLeft(2, '0'),
    );
    _dayController = TextEditingController(
      text: _currentDate.day.toString().padLeft(2, '0'),
    );

    _yearFocus = FocusNode();
    _monthFocus = FocusNode();
    _dayFocus = FocusNode();

    _yearFocus.addListener(_onYearFocusChanged);
    _monthFocus.addListener(_onMonthFocusChanged);
    _dayFocus.addListener(_onDayFocusChanged);
  }

  @override
  void didUpdateWidget(DateInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialDate != widget.initialDate) {
      _currentDate = widget.initialDate;
      _yearController.text = _currentDate.year.toString();
      _monthController.text = _currentDate.month.toString().padLeft(2, '0');
      _dayController.text = _currentDate.day.toString().padLeft(2, '0');
    }
  }

  @override
  void dispose() {
    _yearController.dispose();
    _monthController.dispose();
    _dayController.dispose();
    _yearFocus.removeListener(_onYearFocusChanged);
    _monthFocus.removeListener(_onMonthFocusChanged);
    _dayFocus.removeListener(_onDayFocusChanged);
    _yearFocus.dispose();
    _monthFocus.dispose();
    _dayFocus.dispose();
    super.dispose();
  }

  void _onYearFocusChanged() {
    if (!_yearFocus.hasFocus) {
      _completeYear();
    }
  }

  void _completeYear() {
    final value = _yearController.text;
    if (value.isEmpty) return;

    int year = int.tryParse(value) ?? DateTime.now().year;

    if (value.length <= 2) {
      final twoDigitYear = year % 100;
      if (twoDigitYear >= 12 && twoDigitYear <= 99) {
        year = 2000 + twoDigitYear;
      } else if (twoDigitYear >= 0 && twoDigitYear < 12) {
        year = 2100 + twoDigitYear;
      }
    }

    final minYear = widget.firstDate?.year ?? _minYear;
    final maxYear = widget.lastDate?.year ?? _maxYear;
    year = year.clamp(minYear, maxYear);
    _yearController.text = year.toString();
    _updateDate();
  }

  void _onYearChanged(String value) {
    if (value.length == 4) {
      int year = int.tryParse(value) ?? DateTime.now().year;
      final minYear = widget.firstDate?.year ?? _minYear;
      final maxYear = widget.lastDate?.year ?? _maxYear;
      year = year.clamp(minYear, maxYear);
      _yearController.text = year.toString();
      _monthFocus.requestFocus();
      _updateDate();
    }
  }

  void _onMonthFocusChanged() {
    if (!_monthFocus.hasFocus) {
      _completeMonth();
    }
  }

  void _completeMonth() {
    final value = _monthController.text;
    if (value.isEmpty) return;

    int month = int.tryParse(value) ?? 1;
    month = month.clamp(1, 12);
    _monthController.text = month.toString().padLeft(2, '0');
    _updateDate();
  }

  void _onMonthChanged(String value) {
    if (value.length == 2) {
      int month = int.tryParse(value) ?? 1;
      month = month.clamp(1, 12);
      _monthController.text = month.toString().padLeft(2, '0');
      if (widget.showDay) {
        _dayFocus.requestFocus();
      } else {
        _monthFocus.unfocus();
      }
      _updateDate();
    } else if (value.length == 1 && (int.tryParse(value) ?? 0) > 1) {
      _monthController.text = value.padLeft(2, '0');
      if (widget.showDay) {
        _dayFocus.requestFocus();
      } else {
        _monthFocus.unfocus();
      }
      _updateDate();
    }
  }

  void _onDayFocusChanged() {
    if (!_dayFocus.hasFocus) {
      _completeDay();
    }
  }

  void _completeDay() {
    final value = _dayController.text;
    if (value.isEmpty) return;

    int day = int.tryParse(value) ?? 1;
    day = day.clamp(1, 31);
    _dayController.text = day.toString().padLeft(2, '0');
    _updateDate();
  }

  void _onDayChanged(String value) {
    if (value.length == 2) {
      int day = int.tryParse(value) ?? 1;
      day = day.clamp(1, 31);
      _dayController.text = day.toString().padLeft(2, '0');
      _dayFocus.unfocus();
      _updateDate();
    } else if (value.length == 1 && (int.tryParse(value) ?? 0) > 3) {
      _dayController.text = value.padLeft(2, '0');
      _dayFocus.unfocus();
      _updateDate();
    }
  }

  void _updateDate() {
    try {
      final year = int.parse(_yearController.text);
      final month = _monthController.text.isNotEmpty
          ? int.parse(_monthController.text)
          : _currentDate.month;
      final day = widget.showDay && _dayController.text.isNotEmpty
          ? int.parse(_dayController.text)
          : 1;

      final newDate = DateTime(year, month, day);

      DateTime clampedDate = newDate;
      if (widget.firstDate != null && newDate.isBefore(widget.firstDate!)) {
        clampedDate = widget.firstDate!;
      }
      if (widget.lastDate != null && newDate.isAfter(widget.lastDate!)) {
        clampedDate = widget.lastDate!;
      }

      _currentDate = clampedDate;
      widget.onChanged?.call(_currentDate);
    } catch (_) {}
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _currentDate,
      firstDate: widget.firstDate ?? DateTime(_minYear),
      lastDate: widget.lastDate ?? DateTime(_maxYear, 12, 31),
      locale: const Locale('zh', 'CN'),
    );
    if (picked != null) {
      setState(() {
        _currentDate = picked;
        _yearController.text = picked.year.toString();
        _monthController.text = picked.month.toString().padLeft(2, '0');
        _dayController.text = picked.day.toString().padLeft(2, '0');
      });
      widget.onChanged?.call(_currentDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _yearController,
                focusNode: _yearFocus,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 4,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'YYYY',
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                ),
                onChanged: _onYearChanged,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '-',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _monthController,
                focusNode: _monthFocus,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 2,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'MM',
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                ),
                onChanged: _onMonthChanged,
              ),
            ),
            if (widget.showDay) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '-',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _dayController,
                  focusNode: _dayFocus,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 2,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'DD',
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                  ),
                  onChanged: _onDayChanged,
                ),
              ),
            ],
            if (widget.showDatePicker) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _accentColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    color: _accentColor,
                    size: 20,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
