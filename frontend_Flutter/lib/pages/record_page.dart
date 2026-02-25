import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/local_db_service.dart';
import '../widgets/date_input_field.dart';
import '../widgets/record_form_selectors.dart';
import '../widgets/app_header.dart';
import '../providers/theme_provider.dart';
import '../theme/theme_colors.dart';
import '../theme/theme_decorations.dart';
import '../utils/animations.dart';
import '../utils/responsive_utils.dart';

class RecordPage extends StatefulWidget {
  const RecordPage({super.key});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  bool _isTimerMode = false;
  bool _isTimerRunning = false;
  int _timerSeconds = 0;
  Timer? _timer;

  DateTime _selectedDate = DateTime.now();
  final _timeController = TextEditingController();
  final _durationController = TextEditingController();
  final _notesController = TextEditingController();

  int _maxYear = 2112;
  static const int _minYear = 2012;

  int _stoolType = 4;
  String _color = 'brown';
  int _smellLevel = 2;
  String _feeling = 'smooth';
  List<String> _symptoms = [];

  bool _submitting = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _loadMaxYear();
    _timeController.text = DateFormat('HH:mm').format(DateTime.now());
  }

  Future<void> _loadMaxYear() async {
    final savedValue = await LocalDbService.getSetting('max_year');
    setState(() {
      _maxYear = int.tryParse(savedValue ?? '') ?? 2112;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timeController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _getDateString() {
    return '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
  }

  void _startTimer() {
    setState(() {
      _isTimerRunning = true;
      _timerSeconds = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timerSeconds++;
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _durationController.text = (_timerSeconds / 60).ceil().toString();
      _timeController.text = DateFormat('HH:mm').format(DateTime.now());
    });
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _message = null;
    });

    try {
      await ApiService.createRecord(
        recordDate: _getDateString(),
        recordTime: _timeController.text,
        durationMinutes:
            _durationController.text.isNotEmpty
                ? int.parse(_durationController.text)
                : null,
        stoolType: _stoolType,
        color: _color,
        smellLevel: _smellLevel,
        feeling: _feeling,
        symptoms: _symptoms.isNotEmpty ? _symptoms : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );
      setState(() {
        _message = '记录成功！';
      });
      _resetForm();
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      setState(() {
        _message = errorMsg;
      });
    } finally {
      setState(() {
        _submitting = false;
      });
    }
  }

  void _resetForm() {
    final now = DateTime.now();
    _selectedDate = now;
    _timeController.text = DateFormat('HH:mm').format(DateTime.now());
    _durationController.clear();
    _notesController.clear();
    setState(() {
      _stoolType = 4;
      _color = 'brown';
      _smellLevel = 2;
      _feeling = 'smooth';
      _symptoms = [];
      _timerSeconds = 0;
    });
  }

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
              const AppHeader(title: '记录排便', showBackButton: true),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: ResponsiveUtils.responsivePadding(context),
                      child: ResponsiveUtils.constrainedContent(
                        context: context,
                        maxWidth: 600,
                        child: Column(
                          children: [
                            _buildModeToggle(colors),
                            const SizedBox(height: 16),
                            if (_isTimerMode) _buildTimerSection(colors),
                            _buildFormSection(colors, constraints),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeToggle(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: ThemeDecorations.card(context),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isTimerMode = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isTimerMode ? colors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '手动输入',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color:
                        !_isTimerMode
                            ? colors.textOnPrimary
                            : colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isTimerMode = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isTimerMode ? colors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '计时器',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color:
                        _isTimerMode
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
    );
  }

  Widget _buildTimerSection(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: ThemeDecorations.card(context),
      child: Column(
        children: [
          Text(
            _formatTime(_timerSeconds),
            style: TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              color: colors.primary,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 24),
          if (!_isTimerRunning)
            ElevatedButton(
              onPressed: _startTimer,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.textOnPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text('开始计时', style: TextStyle(fontSize: 16)),
            )
          else
            ElevatedButton(
              onPressed: _stopTimer,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.error,
                foregroundColor: colors.textOnPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text('停止计时', style: TextStyle(fontSize: 16)),
            ),
          if (_durationController.text.isNotEmpty && !_isTimerRunning)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                '已记录时长: ${_durationController.text} 分钟',
                style: TextStyle(color: colors.textSecondary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFormSection(ThemeColors colors, BoxConstraints constraints) {
    final isNarrow = constraints.maxWidth < 400;

    return AnimatedEntrance(
      duration: AppAnimations.durationSlow,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: ThemeDecorations.card(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isNarrow)
              Column(
                children: [
                  DateInputField(
                    label: '日期',
                    initialDate: _selectedDate,
                    firstDate: DateTime(_minYear),
                    lastDate: DateTime(_maxYear, 12, 31),
                    onChanged: (date) {
                      setState(() {
                        _selectedDate = date;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    '时间',
                    _timeController,
                    readOnly: true,
                    colors: colors,
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: DateInputField(
                      label: '日期',
                      initialDate: _selectedDate,
                      firstDate: DateTime(_minYear),
                      lastDate: DateTime(_maxYear, 12, 31),
                      onChanged: (date) {
                        setState(() {
                          _selectedDate = date;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      '时间',
                      _timeController,
                      readOnly: true,
                      colors: colors,
                    ),
                  ),
                ],
              ),
            if (!_isTimerMode) ...[
              const SizedBox(height: 16),
              _buildTextField(
                '时长（分钟）',
                _durationController,
                keyboardType: TextInputType.number,
                colors: colors,
              ),
            ],
            const SizedBox(height: 16),
            StoolTypeSelector(
              value: _stoolType,
              onChanged: (v) => setState(() => _stoolType = v),
              colors: colors,
            ),
            const SizedBox(height: 16),
            ColorSelector(
              value: _color,
              onChanged: (v) => setState(() => _color = v),
              colors: colors,
            ),
            const SizedBox(height: 16),
            SmellSelector(
              value: _smellLevel,
              onChanged: (v) => setState(() => _smellLevel = v),
              colors: colors,
            ),
            const SizedBox(height: 16),
            FeelingSelector(
              value: _feeling,
              onChanged: (v) => setState(() => _feeling = v),
              colors: colors,
            ),
            const SizedBox(height: 16),
            SymptomsSelector(
              value: _symptoms,
              onChanged: (v) => setState(() => _symptoms = v),
              colors: colors,
            ),
            const SizedBox(height: 16),
            _buildTextField('备注', _notesController, maxLines: 2, colors: colors),
            if (_message != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      _message!.contains('成功')
                          ? colors.success.withValues(alpha: 0.1)
                          : colors.errorBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color:
                        _message!.contains('成功')
                            ? colors.success
                            : colors.error,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            ScaleOnTap(
              onTap: _submitting ? null : _submit,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.textOnPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _submitting ? '保存中...' : '保存记录',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    bool readOnly = false,
    TextInputType? keyboardType,
    required ThemeColors colors,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          readOnly: readOnly,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            filled: true,
            fillColor: colors.surface,
          ),
        ),
      ],
    );
  }
}
