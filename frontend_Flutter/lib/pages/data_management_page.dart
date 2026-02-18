import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../widgets/calendar_widget.dart';
import 'data_page.dart';
import 'analysis_page.dart';
import 'settings_page.dart';
import 'login_page.dart';

class DataManagementPage extends StatefulWidget {
  const DataManagementPage({super.key});

  @override
  State<DataManagementPage> createState() => _DataManagementPageState();
}

class _DataManagementPageState extends State<DataManagementPage> {
  List<BowelRecord> _records = [];
  Map<String, int> _dailyCounts = {};
  List<String> _noBowelDates = [];
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _calendarExpanded = true;

  DateTime? _selectedDate;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  String _viewMode = 'all';

  final Map<int, String> _stoolTypeEmojis = {
    1: '🪨',
    2: '🥜',
    3: '🌭',
    4: '🍌',
    5: '🫘',
    6: '🥣',
    7: '💧',
  };

  final Map<String, String> _colorLabels = {
    'brown': '棕色',
    'dark_brown': '深棕',
    'light_brown': '浅棕',
    'green': '绿色',
    'yellow': '黄色',
    'black': '黑色',
    'red': '红色',
  };

  final Map<String, String> _feelingLabels = {
    'smooth': '顺畅',
    'difficult': '困难',
    'painful': '疼痛',
    'urgent': '急迫',
    'incomplete': '不尽',
  };

  @override
  void initState() {
    super.initState();
    _loadDailyCounts();
    _loadRecords();
  }

  Future<void> _loadDailyCounts() async {
    try {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month - 2, 1);
      final counts = await ApiService.getDailyCounts(
        startDate: _formatDate(startDate),
        endDate: _formatDate(now),
      );
      setState(() {
        _dailyCounts = counts.dailyCounts;
        _noBowelDates = counts.noBowelDates;
      });
    } catch (e) {
      print('加载每日统计失败: $e');
    }
  }

  Future<void> _loadRecords({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMore = true;
        _records = [];
      });
    }

    setState(() {
      if (refresh) {
        _loading = true;
      } else {
        _loadingMore = true;
      }
      _error = null;
    });

    try {
      String? startDate;
      String? endDate;

      if (_viewMode == 'single' && _selectedDate != null) {
        startDate = _formatDate(_selectedDate!);
        endDate = _formatDate(_selectedDate!);
      } else if (_viewMode == 'range' &&
          _rangeStart != null &&
          _rangeEnd != null) {
        startDate = _formatDate(_rangeStart!);
        endDate = _formatDate(_rangeEnd!);
      }

      final records = await ApiService.getRecords(
        startDate: startDate,
        endDate: endDate,
        page: _currentPage,
        limit: 20,
      );

      setState(() {
        if (refresh) {
          _records = records;
        } else {
          _records.addAll(records);
        }
        _hasMore = records.length == 20;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      final isAuthError =
          errorMsg.contains('认证') ||
          errorMsg.contains('token') ||
          errorMsg.contains('令牌') ||
          errorMsg.contains('Authenticated') ||
          errorMsg.contains('Unauthorized') ||
          errorMsg.contains('unauthorized');
      if (isAuthError) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        await prefs.remove('user');
        setState(() {
          _error = '登录已过期，请重新登录';
          _loading = false;
          _loadingMore = false;
        });
      } else {
        setState(() {
          _error = errorMsg;
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  Future<void> _deleteRecord(String recordId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条记录吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.deleteRecord(recordId);
        setState(() {
          _records.removeWhere((r) => r.recordId == recordId);
        });
        await _loadDailyCounts();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('记录已删除')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '删除失败: ${e.toString().replaceAll('Exception: ', '')}',
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _markNoBowelForSelection() async {
    List<DateTime> datesToMark = [];

    if (_viewMode == 'single' && _selectedDate != null) {
      datesToMark = [_selectedDate!];
    } else if (_viewMode == 'range' &&
        _rangeStart != null &&
        _rangeEnd != null) {
      final days = _rangeEnd!.difference(_rangeStart!).inDays + 1;
      for (int i = 0; i < days; i++) {
        final date = _rangeStart!.add(Duration(days: i));
        final dateStr = _formatDate(date);
        if (!_noBowelDates.contains(dateStr)) {
          datesToMark.add(date);
        }
      }
    }

    if (datesToMark.isEmpty) return;

    int successCount = 0;
    int failCount = 0;

    for (final date in datesToMark) {
      try {
        await ApiService.markNoBowel(_formatDate(date));
        successCount++;
      } catch (e) {
        failCount++;
      }
    }

    await _loadDailyCounts();

    if (mounted) {
      if (failCount == 0) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('已标注 $successCount 天为无排便')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('成功 $successCount 天，失败 $failCount 天')),
        );
      }
    }
  }

  Future<void> _unmarkNoBowelForSelection() async {
    List<DateTime> datesToUnmark = [];

    if (_viewMode == 'single' && _selectedDate != null) {
      datesToUnmark = [_selectedDate!];
    } else if (_viewMode == 'range' &&
        _rangeStart != null &&
        _rangeEnd != null) {
      final days = _rangeEnd!.difference(_rangeStart!).inDays + 1;
      for (int i = 0; i < days; i++) {
        final date = _rangeStart!.add(Duration(days: i));
        final dateStr = _formatDate(date);
        if (_noBowelDates.contains(dateStr)) {
          datesToUnmark.add(date);
        }
      }
    }

    if (datesToUnmark.isEmpty) return;

    int successCount = 0;
    int failCount = 0;

    for (final date in datesToUnmark) {
      try {
        await ApiService.unmarkNoBowel(_formatDate(date));
        successCount++;
      } catch (e) {
        failCount++;
      }
    }

    await _loadDailyCounts();

    if (mounted) {
      if (failCount == 0) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('已取消 $successCount 天的无排便标注')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('成功 $successCount 天，失败 $failCount 天')),
        );
      }
    }
  }

  void _showRecordDetail(BowelRecord record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      record.isNoBowel ? '无排便记录' : '记录详情',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteRecord(record.recordId);
                      },
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('删除'),
                    ),
                  ],
                ),
                const Divider(),
                if (record.lid != null) _buildLidRow(record.lid!),
                _buildDetailRow('📅 日期', record.recordDate),
                if (!record.isNoBowel) ...[
                  if (record.recordTime != null)
                    _buildDetailRow('⏰ 时间', record.recordTime!),
                  if (record.durationMinutes != null)
                    _buildDetailRow('⏱️ 时长', '${record.durationMinutes} 分钟'),
                  if (record.stoolType != null)
                    _buildDetailRow(
                      '📊 粪便类型',
                      '${_stoolTypeEmojis[record.stoolType] ?? ''} 类型 ${record.stoolType}',
                    ),
                  if (record.color != null)
                    _buildDetailRow(
                      '🎨 颜色',
                      _colorLabels[record.color] ?? record.color!,
                    ),
                  if (record.smellLevel != null)
                    _buildDetailRow('👃 气味等级', '${record.smellLevel}/5'),
                  if (record.feeling != null)
                    _buildDetailRow(
                      '😊 感受',
                      _feelingLabels[record.feeling] ?? record.feeling!,
                    ),
                  if (record.symptoms != null && record.symptoms!.isNotEmpty)
                    _buildDetailRow('🏥 伴随症状', record.symptoms!),
                  if (record.notes != null && record.notes!.isNotEmpty)
                    _buildDetailRow('📝 备注', record.notes!),
                ],
                const SizedBox(height: 16),
                Text(
                  '创建时间: ${record.createdAt}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLidRow(String lid) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(
            width: 100,
            child: Text(
              '🏷️ LID',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Text(
                  lid,
                  style: const TextStyle(
                    color: Color(0xFF2E7D32),
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: lid));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('LID已复制'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.copy, size: 14, color: Color(0xFF2E7D32)),
                        SizedBox(width: 4),
                        Text(
                          '复制',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
      _rangeStart = null;
      _rangeEnd = null;
      _viewMode = 'single';
    });
    _loadRecords(refresh: true);
  }

  void _onDateRangeSelected(DateTime start, DateTime end) {
    setState(() {
      _selectedDate = null;
      _rangeStart = start;
      _rangeEnd = end;
      _viewMode = 'range';
    });
    _loadRecords(refresh: true);
  }

  void _clearSelection() {
    setState(() {
      _selectedDate = null;
      _rangeStart = null;
      _rangeEnd = null;
      _viewMode = 'all';
    });
    _loadRecords(refresh: true);
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
                child: _loading && _records.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null && _records.isEmpty
                    ? _buildErrorWidget()
                    : _buildContent(),
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
          const Expanded(
            child: Text(
              '数据管理',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
          ),
          if (_viewMode != 'all')
            TextButton(onPressed: _clearSelection, child: const Text('查看全部')),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    final isAuthError = _error!.contains('登录');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔒', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (isAuthError)
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
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🔑', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 8),
                    Text('去登录', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CalendarWidget(
            selectedDate: _selectedDate,
            startDate: _rangeStart,
            endDate: _rangeEnd,
            dailyCounts: _dailyCounts,
            noBowelDates: _noBowelDates,
            onDateSelected: _onDateSelected,
            onDateRangeSelected: _onDateRangeSelected,
            isExpanded: _calendarExpanded,
            onExpandToggle: () {
              setState(() {
                _calendarExpanded = !_calendarExpanded;
              });
            },
          ),
          const SizedBox(height: 16),
          _buildSelectionInfo(),
          const SizedBox(height: 8),
          if (_records.isNotEmpty) _buildRecordList(),
          if (_records.isEmpty && !_loading) _buildEmptyWidget(),
        ],
      ),
    );
  }

  Widget _buildSelectionInfo() {
    if (_viewMode == 'all') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '点击日期查看当天记录，可选择日期范围',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    String infoText;
    if (_viewMode == 'single' && _selectedDate != null) {
      infoText =
          '${_selectedDate!.year}年${_selectedDate!.month}月${_selectedDate!.day}日的记录';
    } else if (_viewMode == 'range' &&
        _rangeStart != null &&
        _rangeEnd != null) {
      final days = _rangeEnd!.difference(_rangeStart!).inDays + 1;
      infoText =
          '${_rangeStart!.month}月${_rangeStart!.day}日 - ${_rangeEnd!.month}月${_rangeEnd!.day}日 ($days天)';
    } else {
      infoText = '';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_list, color: Color(0xFF2E7D32), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              infoText,
              style: const TextStyle(
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '${_records.length}条',
            style: const TextStyle(
              color: Color(0xFF2E7D32),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    bool canMarkNoBowel = false;
    bool isAlreadyMarked = false;
    int daysToMark = 0;

    if (_viewMode == 'single' && _selectedDate != null) {
      final dateStr = _formatDate(_selectedDate!);
      final hasRecords =
          _dailyCounts.containsKey(dateStr) && _dailyCounts[dateStr]! > 0;
      canMarkNoBowel = !hasRecords;
      isAlreadyMarked = _noBowelDates.contains(dateStr);
      daysToMark = 1;
    } else if (_viewMode == 'range' &&
        _rangeStart != null &&
        _rangeEnd != null) {
      daysToMark = _rangeEnd!.difference(_rangeStart!).inDays + 1;
      int noBowelCount = 0;
      int hasRecordCount = 0;

      for (int i = 0; i < daysToMark; i++) {
        final date = _rangeStart!.add(Duration(days: i));
        final dateStr = _formatDate(date);
        if (_dailyCounts.containsKey(dateStr) && _dailyCounts[dateStr]! > 0) {
          hasRecordCount++;
        } else if (_noBowelDates.contains(dateStr)) {
          noBowelCount++;
        }
      }

      canMarkNoBowel = hasRecordCount == 0;
      isAlreadyMarked = noBowelCount == daysToMark;
    }

    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Text('📭', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            _viewMode == 'all' ? '暂无记录数据' : '该时间段暂无记录',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          if (_viewMode != 'all') ...[
            const SizedBox(height: 16),
            if (canMarkNoBowel && !isAlreadyMarked)
              ElevatedButton.icon(
                onPressed: () => _markNoBowelForSelection(),
                icon: const Icon(Icons.block, size: 18),
                label: Text(
                  '标注为"无排便"${daysToMark > 1 ? ' ($daysToMark天)' : ''}',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              )
            else if (isAlreadyMarked)
              ElevatedButton.icon(
                onPressed: () => _unmarkNoBowelForSelection(),
                icon: const Icon(Icons.remove_circle_outline, size: 18),
                label: Text(
                  '取消"无排便"标注${daysToMark > 1 ? ' ($daysToMark天)' : ''}',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecordList() {
    return Column(
      children: [
        ...(_records
            .where((r) => !r.isNoBowel)
            .map((record) => _buildRecordCard(record))),
        ...(_records
            .where((r) => r.isNoBowel)
            .map((record) => _buildNoBowelCard(record))),
        if (_hasMore && _viewMode != 'single')
          Padding(
            padding: const EdgeInsets.all(16),
            child: _loadingMore
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () {
                      _currentPage++;
                      _loadRecords();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                    ),
                    child: const Text('加载更多'),
                  ),
          ),
      ],
    );
  }

  Widget _buildRecordCard(BowelRecord record) {
    return GestureDetector(
      onTap: () => _showRecordDetail(record),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  _stoolTypeEmojis[record.stoolType] ?? '📝',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        record.recordDate,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      if (record.recordTime != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          record.recordTime!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (record.lid != null)
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: record.lid!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('LID已复制'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF2E7D32,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(
                                  0xFF2E7D32,
                                ).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  record.lid!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF2E7D32),
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.copy,
                                  size: 12,
                                  color: Color(0xFF2E7D32),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (record.stoolType != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '类型${record.stoolType}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      if (record.durationMinutes != null)
                        Text(
                          '${record.durationMinutes}分钟',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                  if (record.feeling != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _feelingLabels[record.feeling] ?? record.feeling!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _deleteRecord(record.recordId),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.delete_outline,
                  color: Colors.grey[400],
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoBowelCard(BowelRecord record) {
    return GestureDetector(
      onTap: () => _showRecordDetail(record),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('⭕', style: TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.recordDate,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (record.lid != null)
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: record.lid!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('LID已复制'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.grey[400]!),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  record.lid!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.copy,
                                  size: 12,
                                  color: Colors.grey[600],
                                ),
                              ],
                            ),
                          ),
                        ),
                      Text(
                        '无排便',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _deleteRecord(record.recordId),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.delete_outline,
                  color: Colors.grey[400],
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
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
