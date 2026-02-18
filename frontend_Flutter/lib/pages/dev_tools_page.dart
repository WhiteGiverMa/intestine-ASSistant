import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../widgets/date_input_field.dart';
import 'login_page.dart';

const List<Map<String, String>> COLORS = [
  {'value': 'brown', 'label': '棕色'},
  {'value': 'dark_brown', 'label': '深棕'},
  {'value': 'light_brown', 'label': '浅棕'},
  {'value': 'green', 'label': '绿色'},
  {'value': 'yellow', 'label': '黄色'},
  {'value': 'black', 'label': '黑色'},
  {'value': 'red', 'label': '红色'},
];

const List<Map<String, String>> FEELINGS = [
  {'value': 'smooth', 'label': '顺畅'},
  {'value': 'difficult', 'label': '困难'},
  {'value': 'painful', 'label': '疼痛'},
  {'value': 'urgent', 'label': '急迫'},
  {'value': 'incomplete', 'label': '不尽'},
];

const List<String> SYMPTOMS = ['腹痛', '腹胀', '恶心', '便血', '粘液'];

int randomInt(int min, int max) {
  return min + (DateTime.now().microsecondsSinceEpoch % (max - min + 1));
}

T randomChoice<T>(List<T> arr) {
  return arr[randomInt(0, arr.length - 1)];
}

List<Map<String, dynamic>> generateRandomRecords(
  int count,
  DateTime startDate,
) {
  final records = <Map<String, dynamic>>[];
  for (int i = 0; i < count; i++) {
    final date = startDate.add(Duration(days: i));
    final hour = randomInt(6, 22).toString().padLeft(2, '0');
    final minute = randomInt(0, 59).toString().padLeft(2, '0');

    final record = {
      'record_date':
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'record_time': '$hour:$minute',
      'duration_minutes': randomInt(1, 15),
      'stool_type': randomInt(1, 7),
      'color': randomChoice(COLORS)['value'],
      'smell_level': randomInt(1, 5),
      'feeling': randomChoice(FEELINGS)['value'],
      'symptoms': DateTime.now().microsecondsSinceEpoch % 10 > 6
          ? [randomChoice(SYMPTOMS)]
          : <String>[],
      'notes': '',
    };
    records.add(record);
  }
  return records;
}

List<Map<String, dynamic>> generateRangedRandomRecords(
  int count,
  DateTime startDate,
) {
  final records = <Map<String, dynamic>>[];
  final baseHour = randomInt(7, 9);
  final baseMinute = randomInt(0, 59);
  final baseDuration = randomInt(3, 8);
  final baseStoolType = randomInt(3, 5);
  final baseSmellLevel = randomInt(2, 3);
  final baseColor = randomChoice(COLORS.sublist(0, 3))['value'] as String;
  final baseFeeling = randomChoice(FEELINGS.sublist(0, 2))['value'] as String;

  for (int i = 0; i < count; i++) {
    final date = startDate.add(Duration(days: i));

    final hourOffset = randomInt(-2, 2);
    final hour = (baseHour + hourOffset).clamp(6, 22);
    final minuteOffset = randomInt(-15, 15);
    final minute = (baseMinute + minuteOffset).clamp(0, 59);

    final durationOffset = randomInt(-2, 2);
    final duration = (baseDuration + durationOffset).clamp(1, 15);

    final stoolTypeOffset = randomInt(-1, 1);
    final stoolType = (baseStoolType + stoolTypeOffset).clamp(1, 7);

    final smellOffset = randomInt(-1, 1);
    final smellLevel = (baseSmellLevel + smellOffset).clamp(1, 5);

    String color;
    if (randomInt(0, 10) > 7) {
      color = randomChoice(COLORS)['value'] as String;
    } else {
      color = baseColor;
    }

    String feeling;
    if (randomInt(0, 10) > 8) {
      feeling = randomChoice(FEELINGS)['value'] as String;
    } else {
      feeling = baseFeeling;
    }

    List<String> symptoms;
    if (i > 0 && randomInt(0, 10) > 8) {
      symptoms = [randomChoice(SYMPTOMS)];
    } else {
      symptoms = [];
    }

    final record = {
      'record_date':
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'record_time':
          '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
      'duration_minutes': duration,
      'stool_type': stoolType,
      'color': color,
      'smell_level': smellLevel,
      'feeling': feeling,
      'symptoms': symptoms,
      'notes': '',
    };
    records.add(record);
  }
  return records;
}

class DevToolsPage extends StatefulWidget {
  const DevToolsPage({super.key});

  @override
  State<DevToolsPage> createState() => _DevToolsPageState();
}

class _DevToolsPageState extends State<DevToolsPage> {
  bool _generating = false;
  String? _message;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 6));

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
                      _buildTestGeneratorSection(),
                      if (_message != null) ...[
                        const SizedBox(height: 16),
                        _buildMessage(),
                      ],
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
            '开发者工具包',
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

  Widget _buildTestGeneratorSection() {
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
          const Row(
            children: [
              Text('🎲', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text(
                '测试数据生成器',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 24),
          Text(
            '生成连续日期的随机排便数据，用于测试AI分析功能',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          DateInputField(
            label: '开始日期',
            initialDate: _startDate,
            firstDate: DateTime(2020),
            lastDate: _endDate,
            accentColor: Colors.deepPurple,
            onChanged: (date) {
              setState(() {
                _startDate = date;
                if (_endDate.isBefore(_startDate)) {
                  _endDate = _startDate;
                }
              });
            },
          ),
          const SizedBox(height: 12),
          DateInputField(
            label: '结束日期',
            initialDate: _endDate,
            firstDate: _startDate,
            lastDate: DateTime.now().add(const Duration(days: 365)),
            accentColor: Colors.teal,
            onChanged: (date) {
              setState(() {
                _endDate = date;
              });
            },
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '共 $_dayCount 天',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '完全随机模式：',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  '• 时间：随机 06:00 - 22:59\n'
                  '• 时长：随机 1-15 分钟\n'
                  '• 粪便形态：随机类型 1-7\n'
                  '• 颜色/气味/感受：完全随机',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _generating ? null : _handleGenerateTestData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _generating ? '生成中...' : '🎲 完全随机生成',
                style: const TextStyle(fontSize: 14, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),
          const Text(
            '范围随机模式',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            '生成有规律的数据，时间与排便情况方差较小',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '范围随机模式特点：',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  '• 时间：固定基准时间 ± 2小时\n'
                  '• 时长：基准时长 ± 2分钟\n'
                  '• 粪便形态：基准类型 ± 1（正常范围）\n'
                  '• 颜色：80%保持一致，20%随机\n'
                  '• 排便感受：90%保持顺畅/正常',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _generating ? null : _handleGenerateRangedTestData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _generating ? '生成中...' : '📊 范围随机生成',
                style: const TextStyle(fontSize: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage() {
    final isSuccess = _message!.contains('成功');
    final isAuthError = _message!.contains('登录');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSuccess ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            _message!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isSuccess ? Colors.green : Colors.red,
            ),
          ),
          if (isAuthError) ...[
            const SizedBox(height: 12),
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
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🔑', style: TextStyle(fontSize: 14)),
                  SizedBox(width: 6),
                  Text(
                    '去登录',
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _isAuthError(String errorMsg) {
    final lowerMsg = errorMsg.toLowerCase();
    return lowerMsg.contains('认证') ||
        lowerMsg.contains('token') ||
        lowerMsg.contains('令牌') ||
        lowerMsg.contains('authenticated') ||
        lowerMsg.contains('unauthorized');
  }

  Future<void> _handleAuthError() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    if (mounted) {
      setState(() => _message = '登录已过期，请重新登录');
    }
  }

  int get _dayCount {
    return _endDate.difference(_startDate).inDays + 1;
  }

  Future<void> _handleGenerateTestData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      setState(() => _message = '请先登录');
      return;
    }

    setState(() {
      _generating = true;
      _message = null;
    });

    try {
      final records = generateRandomRecords(_dayCount, _startDate);
      int successCount = 0;

      for (final record in records) {
        try {
          await ApiService.createRecord(
            recordDate: record['record_date'] as String,
            recordTime: record['record_time'] as String,
            durationMinutes: record['duration_minutes'] as int,
            stoolType: record['stool_type'] as int,
            color: record['color'] as String,
            smellLevel: record['smell_level'] as int,
            feeling: record['feeling'] as String,
            symptoms: (record['symptoms'] as List).cast<String>(),
            notes: record['notes'] as String,
          );
          successCount++;
        } catch (e) {}
      }

      setState(() {
        _message = '成功生成 $successCount/$_dayCount 条测试数据';
      });
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      if (_isAuthError(errorMsg)) {
        await _handleAuthError();
      } else {
        setState(() {
          _message = errorMsg;
        });
      }
    } finally {
      setState(() {
        _generating = false;
      });
    }
  }

  Future<void> _handleGenerateRangedTestData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      setState(() => _message = '请先登录');
      return;
    }

    setState(() {
      _generating = true;
      _message = null;
    });

    try {
      final records = generateRangedRandomRecords(_dayCount, _startDate);
      int successCount = 0;

      for (final record in records) {
        try {
          await ApiService.createRecord(
            recordDate: record['record_date'] as String,
            recordTime: record['record_time'] as String,
            durationMinutes: record['duration_minutes'] as int,
            stoolType: record['stool_type'] as int,
            color: record['color'] as String,
            smellLevel: record['smell_level'] as int,
            feeling: record['feeling'] as String,
            symptoms: (record['symptoms'] as List).cast<String>(),
            notes: record['notes'] as String,
          );
          successCount++;
        } catch (e) {}
      }

      setState(() {
        _message = '成功生成 $successCount/$_dayCount 条范围随机数据';
      });
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      if (_isAuthError(errorMsg)) {
        await _handleAuthError();
      } else {
        setState(() {
          _message = errorMsg;
        });
      }
    } finally {
      setState(() {
        _generating = false;
      });
    }
  }
}
