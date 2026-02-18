import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../widgets/date_input_field.dart';
import 'data_page.dart';
import 'analysis_page.dart';
import 'settings_page.dart';
import 'login_page.dart';

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
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _maxYear = prefs.getInt('max_year') ?? 2112;
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
        durationMinutes: _durationController.text.isNotEmpty
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
      final lowerMsg = errorMsg.toLowerCase();
      final isAuthError =
          lowerMsg.contains('认证') ||
          lowerMsg.contains('token') ||
          lowerMsg.contains('令牌') ||
          lowerMsg.contains('authenticated') ||
          lowerMsg.contains('unauthorized');
      if (isAuthError) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        await prefs.remove('user');
        setState(() {
          _message = '登录已过期，请重新登录';
        });
      } else {
        setState(() {
          _message = errorMsg;
        });
      }
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE8F5E9), Color(0xFFB2DFDB)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildModeToggle(),
                      const SizedBox(height: 16),
                      if (_isTimerMode) _buildTimerSection(),
                      _buildFormSection(),
                    ],
                  ),
                ),
              ),
              _buildBottomNav(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Text(
              '←',
              style: TextStyle(fontSize: 20, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            '记录排便',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isTimerMode = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isTimerMode
                      ? const Color(0xFF2E7D32)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '手动输入',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: !_isTimerMode ? Colors.white : Colors.grey[600],
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
                  color: _isTimerMode
                      ? const Color(0xFF2E7D32)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '计时器',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _isTimerMode ? Colors.white : Colors.grey[600],
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

  Widget _buildTimerSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 16),
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
          Text(
            _formatTime(_timerSeconds),
            style: const TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 24),
          if (!_isTimerRunning)
            ElevatedButton(
              onPressed: _startTimer,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
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
                backgroundColor: Colors.red,
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
                style: const TextStyle(color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFormSection() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                child: _buildTextField('时间', _timeController, readOnly: true),
              ),
            ],
          ),
          if (!_isTimerMode) ...[
            const SizedBox(height: 16),
            _buildTextField(
              '时长（分钟）',
              _durationController,
              keyboardType: TextInputType.number,
            ),
          ],
          const SizedBox(height: 16),
          _buildStoolTypeSelector(),
          const SizedBox(height: 16),
          _buildColorSelector(),
          const SizedBox(height: 16),
          _buildSmellSelector(),
          const SizedBox(height: 16),
          _buildFeelingSelector(),
          const SizedBox(height: 16),
          _buildSymptomsSelector(),
          const SizedBox(height: 16),
          _buildTextField('备注', _notesController, maxLines: 2),
          if (_message != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _message!.contains('成功')
                    ? Colors.green.shade50
                    : (_message!.contains('登录') || _message!.contains('过期'))
                    ? Colors.orange.shade50
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    _message!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _message!.contains('成功')
                          ? Colors.green
                          : (_message!.contains('登录') ||
                                _message!.contains('过期'))
                          ? Colors.orange
                          : Colors.red,
                      fontSize: 15,
                    ),
                  ),
                  if (_message!.contains('登录') || _message!.contains('过期')) ...[
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('🔑', style: TextStyle(fontSize: 16)),
                          SizedBox(width: 8),
                          Text('去登录', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
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
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    bool readOnly = false,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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
          ),
        ),
      ],
    );
  }

  Widget _buildStoolTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '粪便形态（布里斯托分类）',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(7, (index) {
            final type = index + 1;
            final emojis = ['🪨', '🥜', '🌭', '🍌', '🫘', '🥣', '💧'];
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _stoolType = type),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: _stoolType == type
                        ? const Color(0xFF2E7D32)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(emojis[index], style: const TextStyle(fontSize: 20)),
                      Text(
                        '$type',
                        style: TextStyle(
                          fontSize: 12,
                          color: _stoolType == type
                              ? Colors.white
                              : Colors.grey,
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

  Widget _buildColorSelector() {
    final colors = [
      {'value': 'brown', 'label': '棕色', 'color': const Color(0xFF8B4513)},
      {'value': 'dark_brown', 'label': '深棕', 'color': const Color(0xFF5D4037)},
      {'value': 'light_brown', 'label': '浅棕', 'color': const Color(0xFFA1887F)},
      {'value': 'green', 'label': '绿色', 'color': const Color(0xFF4CAF50)},
      {'value': 'yellow', 'label': '黄色', 'color': const Color(0xFFFFEB3B)},
      {'value': 'black', 'label': '黑色', 'color': const Color(0xFF212121)},
      {'value': 'red', 'label': '红色', 'color': const Color(0xFFF44336)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '颜色',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colors.map((c) {
            final isSelected = _color == c['value'];
            return GestureDetector(
              onTap: () => setState(() => _color = c['value'] as String),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: isSelected
                      ? Border.all(color: const Color(0xFF2E7D32), width: 2)
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
                      style: const TextStyle(fontSize: 12),
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

  Widget _buildSmellSelector() {
    final levels = ['无', '轻微', '一般', '较重', '严重'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '气味',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            final level = index + 1;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _smellLevel = level),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _smellLevel == level
                        ? const Color(0xFF2E7D32)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    levels[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: _smellLevel == level ? Colors.white : Colors.grey,
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

  Widget _buildFeelingSelector() {
    final feelings = [
      {'value': 'smooth', 'label': '顺畅', 'emoji': '😊'},
      {'value': 'difficult', 'label': '困难', 'emoji': '😣'},
      {'value': 'painful', 'label': '疼痛', 'emoji': '😫'},
      {'value': 'urgent', 'label': '急迫', 'emoji': '😰'},
      {'value': 'incomplete', 'label': '不尽', 'emoji': '😕'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '排便感受',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: feelings.map((f) {
            final isSelected = _feeling == f['value'];
            return GestureDetector(
              onTap: () => setState(() => _feeling = f['value'] as String),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF2E7D32)
                      : Colors.grey.shade100,
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
                        color: isSelected ? Colors.white : Colors.grey,
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

  Widget _buildSymptomsSelector() {
    final allSymptoms = ['腹痛', '腹胀', '恶心', '便血', '粘液'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '伴随症状',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: allSymptoms.map((s) {
            final isSelected = _symptoms.contains(s);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _symptoms.remove(s);
                  } else {
                    _symptoms.add(s);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF2E7D32)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  s,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? Colors.white : Colors.grey,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem('🏠', '首页', false, () => Navigator.pop(context)),
            _buildNavItem('📊', '数据', false, const DataPage()),
            _buildNavItem('🤖', '分析', false, const AnalysisPage()),
            _buildNavItem('⚙️', '设置', false, const SettingsPage()),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    String emoji,
    String label,
    bool isActive, [
    dynamic target,
  ]) {
    return GestureDetector(
      onTap: target != null
          ? () {
              if (target is VoidCallback) {
                target();
              } else if (target is Widget) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => target),
                );
              }
            }
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isActive ? const Color(0xFF2E7D32) : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
