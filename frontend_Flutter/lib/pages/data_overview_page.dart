// 数据概览页面，整合数据统计与记录管理功能。
//
// @module: data_overview_page
// @type: page
// @layer: frontend
// @depends: [api_service, models, calendar_widget, stats_charts, record_cards]
// @exports: [DataOverviewPage]
// @brief: 整合数据统计与记录管理，支持日期范围筛选、日历视图、统计图表和记录列表。
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../widgets/calendar_widget.dart';
import '../widgets/date_input_field.dart';
import '../widgets/error_dialog.dart';
import '../widgets/compact_tab_switcher.dart';
import '../widgets/stats_charts.dart';
import '../widgets/record_cards.dart';
import '../providers/theme_provider.dart';
import '../theme/theme_colors.dart';
import '../theme/theme_decorations.dart';
import 'data_page.dart';
import 'analysis_page.dart';
import 'settings_page.dart';

class DataOverviewPage extends StatefulWidget {
  const DataOverviewPage({super.key});

  @override
  State<DataOverviewPage> createState() => _DataOverviewPageState();
}

class _DataOverviewPageState extends State<DataOverviewPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Date range
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  DateTime? _selectedDate;
  String _viewMode = 'range';

  // Calendar state
  bool _calendarExpanded = true;
  Map<String, int> _dailyCounts = {};
  List<String> _noBowelDates = [];

  // Stats data
  StatsSummary? _summary;
  StatsTrends? _trends;
  bool _statsLoading = true;
  AppError? _statsError;

  // Records data
  List<BowelRecord> _records = [];
  bool _recordsLoading = true;
  AppError? _recordsError;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _loadingMore = false;

  // Date input fields
  String? _focusedDateField;
  final GlobalKey<DateInputFieldState> _startDateKey =
      GlobalKey<DateInputFieldState>();
  final GlobalKey<DateInputFieldState> _endDateKey =
      GlobalKey<DateInputFieldState>();
  DateTime? _pendingRangeStart;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _initializeDateRange();
    _loadDailyCounts();
    _loadStats();
    _loadRecords();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _initializeDateRange() {
    final now = DateTime.now();
    _rangeEnd = now;
    _rangeStart = now.subtract(const Duration(days: 7));
  }

  Future<void> _loadDailyCounts() async {
    try {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month - 2);
      final counts = await ApiService.getDailyCounts(
        startDate: _formatDate(startDate),
        endDate: _formatDate(now),
      );
      setState(() {
        _dailyCounts = counts.dailyCounts;
        _noBowelDates = counts.noBowelDates;
      });
    } catch (e) {
      debugPrint('加载每日统计失败: $e');
    }
  }

  Future<void> _loadStats() async {
    setState(() {
      _statsLoading = true;
      _statsError = null;
    });

    try {
      String? startDate;
      String? endDate;
      if (_rangeStart != null && _rangeEnd != null) {
        startDate = _formatDate(_rangeStart!);
        endDate = _formatDate(_rangeEnd!);
      }

      final results = await Future.wait([
        ApiService.getStatsSummary(startDate: startDate, endDate: endDate),
        ApiService.getStatsTrends(startDate: startDate, endDate: endDate),
      ]);

      setState(() {
        _summary = results[0] as StatsSummary;
        _trends = results[1] as StatsTrends;
        _statsLoading = false;
      });
    } catch (e) {
      final appError = ErrorHandler.handleError(e);
      if (appError.type == ErrorType.auth) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        await prefs.remove('user');
      }
      setState(() {
        _statsError = appError;
        _statsLoading = false;
      });
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
        _recordsLoading = true;
      } else {
        _loadingMore = true;
      }
      _recordsError = null;
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
      );

      setState(() {
        if (refresh) {
          _records = records;
        } else {
          _records.addAll(records);
        }
        _hasMore = records.length == 20;
        _recordsLoading = false;
        _loadingMore = false;
      });
    } catch (e) {
      final appError = ErrorHandler.handleError(e);
      if (appError.type == ErrorType.auth) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        await prefs.remove('user');
      }
      setState(() {
        _recordsError = appError;
        _recordsLoading = false;
        _loadingMore = false;
      });
    }
  }

  Future<void> _refreshAll() async {
    await _loadDailyCounts();
    await _loadStats();
    await _loadRecords(refresh: true);
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _selectQuickRange(String range) {
    final now = DateTime.now();
    setState(() {
      _viewMode = 'range';
      _selectedDate = null;
      switch (range) {
        case 'week':
          _rangeStart = now.subtract(const Duration(days: 7));
          _rangeEnd = now;
          break;
        case 'month':
          _rangeStart = now.subtract(const Duration(days: 30));
          _rangeEnd = now;
          break;
        case 'year':
          _rangeStart = now.subtract(const Duration(days: 365));
          _rangeEnd = now;
          break;
      }
    });
    _updateDateInputFields();
    _refreshAll();
  }

  void _updateDateInputFields() {
    if (_rangeStart != null) {
      _startDateKey.currentState?.setDate(_rangeStart!);
    }
    if (_rangeEnd != null) {
      _endDateKey.currentState?.setDate(_rangeEnd!);
    }
  }

  void _onDateRangeSelected(DateTime start, DateTime end) {
    setState(() {
      _viewMode = 'range';
      _selectedDate = null;
      _rangeStart = start;
      _rangeEnd = end;
    });
    _updateDateInputFields();
    _refreshAll();
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

  void _onCalendarDateClick(DateTime date) {
    if (_focusedDateField != null) {
      if (_focusedDateField == 'start') {
        _startDateKey.currentState?.setDate(date);
        setState(() {
          _rangeStart = date;
          _viewMode = 'range';
          _selectedDate = null;
          _focusedDateField = 'end';
        });
      } else if (_focusedDateField == 'end') {
        _endDateKey.currentState?.setDate(date);
        setState(() {
          _rangeEnd = date;
          _viewMode = 'range';
          _selectedDate = null;
          _focusedDateField = null;
        });
        _refreshAll();
      }
    } else {
      if (_pendingRangeStart == null) {
        _startDateKey.currentState?.setDate(date);
        setState(() {
          _rangeStart = date;
          _rangeEnd = null;
          _viewMode = 'range';
          _selectedDate = null;
          _pendingRangeStart = date;
        });
      } else {
        final start = date.isBefore(_pendingRangeStart!)
            ? date
            : _pendingRangeStart!;
        final end = date.isBefore(_pendingRangeStart!)
            ? _pendingRangeStart!
            : date;
        _startDateKey.currentState?.setDate(start);
        _endDateKey.currentState?.setDate(end);
        setState(() {
          _rangeStart = start;
          _rangeEnd = end;
          _viewMode = 'range';
          _selectedDate = null;
          _pendingRangeStart = null;
        });
        _refreshAll();
      }
    }
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
              _buildHeader(colors),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [_buildStatsTab(colors), _buildRecordsTab(colors)],
                ),
              ),
              _buildBottomNav(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: ThemeDecorations.header(context),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.arrow_back,
                size: 20,
                color: colors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '数据概览',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CompactTabSwitcher(
              currentIndex: _tabController.index,
              tabs: const [
                CompactTabItem(label: '统计', icon: Icons.bar_chart),
                CompactTabItem(label: '记录', icon: Icons.list_alt),
              ],
              onTabChanged: (index) => _tabController.animateTo(index),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _refreshAll,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.refresh, color: colors.primary, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab(ThemeColors colors) {
    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            _buildDateInputRow(colors),
            const SizedBox(height: 12),
            _buildQuickSelectButtons(colors),
            const SizedBox(height: 12),
            CalendarWidget(
              startDate: _rangeStart,
              endDate: _rangeEnd,
              dailyCounts: _dailyCounts,
              noBowelDates: _noBowelDates,
              onDateSelected: (_) {},
              onDateRangeSelected: _onDateRangeSelected,
              onDateClick: _onCalendarDateClick,
              isExpanded: _calendarExpanded,
              onExpandToggle: () {
                setState(() {
                  _calendarExpanded = !_calendarExpanded;
                });
              },
            ),
            const SizedBox(height: 16),
            if (_statsLoading)
              Center(child: CircularProgressIndicator(color: colors.primary))
            else if (_statsError != null)
              _buildStatsErrorWidget()
            else ...[
              if (_summary != null && _summary!.coverageRate < 0.8)
                _buildCoverageWarning(colors),
              const SizedBox(height: 8),
              StatsGrid(summary: _summary, colors: colors),
              const SizedBox(height: 16),
              TrendChart(trends: _trends, colors: colors),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: StoolTypePieChart(summary: _summary, colors: colors),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TimeDistributionRing(
                      summary: _summary,
                      colors: colors,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordsTab(ThemeColors colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
          _buildSelectionInfo(colors),
          const SizedBox(height: 8),
          if (_recordsLoading && _records.isEmpty)
            Center(child: CircularProgressIndicator(color: colors.primary))
          else if (_recordsError != null && _records.isEmpty)
            _buildRecordsErrorWidget()
          else if (_records.isNotEmpty)
            _buildRecordList(colors)
          else if (!_recordsLoading)
            _buildEmptyWidget(colors),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDateInputRow(ThemeColors colors) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _focusedDateField ??= 'start';
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: ThemeDecorations.card(context),
        child: Row(
          children: [
            Expanded(
              child: DateInputField(
                key: _startDateKey,
                label: '开始日期',
                initialDate: _rangeStart ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: _rangeEnd ?? DateTime.now(),
                showDatePicker: false,
                isExternallyFocused: _focusedDateField == 'start',
                onFocusChanged: (focused) {
                  setState(() {
                    _focusedDateField = focused ? 'start' : null;
                  });
                },
                onChanged: (date) {
                  setState(() {
                    _rangeStart = date;
                    _viewMode = 'range';
                    _selectedDate = null;
                  });
                  _loadStats();
                  _loadRecords(refresh: true);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DateInputField(
                key: _endDateKey,
                label: '结束日期',
                initialDate: _rangeEnd ?? DateTime.now(),
                firstDate: _rangeStart ?? DateTime(2020),
                lastDate: DateTime.now(),
                showDatePicker: false,
                isExternallyFocused: _focusedDateField == 'end',
                onFocusChanged: (focused) {
                  setState(() {
                    _focusedDateField = focused ? 'end' : null;
                  });
                },
                onChanged: (date) {
                  setState(() {
                    _rangeEnd = date;
                    _viewMode = 'range';
                    _selectedDate = null;
                  });
                  _loadStats();
                  _loadRecords(refresh: true);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSelectButtons(ThemeColors colors) {
    return Row(
      children: [
        Expanded(child: _buildQuickButton('本周', 'week', colors)),
        const SizedBox(width: 8),
        Expanded(child: _buildQuickButton('本月', 'month', colors)),
        const SizedBox(width: 8),
        Expanded(child: _buildQuickButton('本年', 'year', colors)),
      ],
    );
  }

  Widget _buildQuickButton(String label, String range, ThemeColors colors) {
    final now = DateTime.now();
    DateTime expectedStart;
    switch (range) {
      case 'week':
        expectedStart = now.subtract(const Duration(days: 7));
        break;
      case 'month':
        expectedStart = now.subtract(const Duration(days: 30));
        break;
      case 'year':
        expectedStart = now.subtract(const Duration(days: 365));
        break;
      default:
        expectedStart = now;
    }

    final isSelected =
        _rangeStart != null &&
        _rangeStart!.year == expectedStart.year &&
        _rangeStart!.month == expectedStart.month &&
        _rangeStart!.day == expectedStart.day;

    return GestureDetector(
      onTap: () => _selectQuickRange(range),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : colors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? colors.primary : colors.divider,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.1),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? colors.textOnPrimary : colors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionInfo(ThemeColors colors) {
    if (_viewMode == 'all') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: colors.textSecondary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '点击日期查看当天记录，可选择日期范围',
                style: TextStyle(color: colors.textSecondary, fontSize: 12),
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
        color: colors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.filter_list, color: colors.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              infoText,
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '${_records.length}条',
            style: TextStyle(
              color: colors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverageWarning(ThemeColors colors) {
    final rate = (_summary!.coverageRate * 100).toInt();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: colors.warning, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '数据覆盖率 $rate%（${_summary!.recordedDays}/${_summary!.days}天），分析结果仅供参考',
              style: TextStyle(fontSize: 13, color: colors.warning),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordList(ThemeColors colors) {
    return Column(
      children: [
        ...(_records
            .where((r) => !r.isNoBowel)
            .map(
              (record) => RecordCard(
                record: record,
                colors: colors,
                onTap: () => _showRecordDetail(record, colors),
                onDelete: () => _deleteRecord(record.recordId),
              ),
            )),
        ...(_records
            .where((r) => r.isNoBowel)
            .map(
              (record) => NoBowelCard(
                record: record,
                colors: colors,
                onTap: () => _showRecordDetail(record, colors),
                onDelete: () => _deleteRecord(record.recordId),
              ),
            )),
        if (_hasMore && _viewMode != 'single')
          Padding(
            padding: const EdgeInsets.all(16),
            child: _loadingMore
                ? CircularProgressIndicator(color: colors.primary)
                : ElevatedButton(
                    onPressed: () {
                      _currentPage++;
                      _loadRecords();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                    ),
                    child: Text(
                      '加载更多',
                      style: TextStyle(color: colors.textOnPrimary),
                    ),
                  ),
          ),
      ],
    );
  }

  Widget _buildEmptyWidget(ThemeColors colors) {
    bool isAlreadyMarked = false;
    int daysToMark = 0;
    int unmarkedDays = 0;

    if (_viewMode == 'single' && _selectedDate != null) {
      final dateStr = _formatDate(_selectedDate!);
      isAlreadyMarked = _noBowelDates.contains(dateStr);
      daysToMark = 1;
      unmarkedDays = isAlreadyMarked ? 0 : 1;
    } else if (_viewMode == 'range' &&
        _rangeStart != null &&
        _rangeEnd != null) {
      daysToMark = _rangeEnd!.difference(_rangeStart!).inDays + 1;
      int noBowelCount = 0;

      for (int i = 0; i < daysToMark; i++) {
        final date = _rangeStart!.add(Duration(days: i));
        final dateStr = _formatDate(date);
        if (_noBowelDates.contains(dateStr)) {
          noBowelCount++;
        }
      }

      isAlreadyMarked = noBowelCount == daysToMark;
      unmarkedDays = daysToMark - noBowelCount;
    }

    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Text('📭', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            _viewMode == 'all' ? '暂无记录数据' : '该时间段暂无记录',
            style: TextStyle(fontSize: 16, color: colors.textSecondary),
          ),
          if (_viewMode != 'all') ...[
            const SizedBox(height: 16),
            if (unmarkedDays > 0)
              ElevatedButton.icon(
                onPressed: () => _markAllAsNoBowel(),
                icon: const Icon(Icons.block, size: 18),
                label: Text(
                  '标注为"无排便"${unmarkedDays > 1 ? ' ($unmarkedDays天)' : ''}',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.textSecondary,
                  foregroundColor: colors.textOnPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            if (isAlreadyMarked)
              ElevatedButton.icon(
                onPressed: () => _unmarkNoBowelForSelection(),
                icon: const Icon(Icons.remove_circle_outline, size: 18),
                label: Text(
                  '取消"无排便"标注${daysToMark > 1 ? ' ($daysToMark天)' : ''}',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.warning,
                  foregroundColor: colors.textOnPrimary,
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

  Widget _buildStatsErrorWidget() {
    if (_statsError == null) return const SizedBox.shrink();
    return ErrorWidgetInline(
      error: _statsError!,
      showCopyButton: _statsError!.type != ErrorType.auth,
      onRetry: _loadStats,
    );
  }

  Widget _buildRecordsErrorWidget() {
    if (_recordsError == null) return const SizedBox.shrink();
    return ErrorWidgetInline(
      error: _recordsError!,
      showCopyButton: _recordsError!.type != ErrorType.auth,
      onRetry: () => _loadRecords(refresh: true),
    );
  }

  Widget _buildBottomNav(ThemeColors colors) {
    return Container(
      decoration: ThemeDecorations.bottomNav(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              '🏠',
              '首页',
              false,
              () => Navigator.pop(context),
              colors,
            ),
            _buildNavItem('📊', '数据', true, const DataPage(), colors),
            _buildNavItem('🤖', '分析', false, const AnalysisPage(), colors),
            _buildNavItem('⚙️', '设置', false, const SettingsPage(), colors),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    String emoji,
    String label,
    bool isActive,
    dynamic target,
    ThemeColors colors,
  ) {
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
              color: isActive ? colors.primary : colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showRecordDetail(BowelRecord record, ThemeColors colors) {
    RecordDetailSheet.show(
      context: context,
      record: record,
      colors: colors,
      onDelete: () => _deleteRecord(record.recordId),
    );
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
        await _loadStats();
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

  Future<void> _markAllAsNoBowel() async {
    String startDate;
    String endDate;

    if (_viewMode == 'single' && _selectedDate != null) {
      startDate = _formatDate(_selectedDate!);
      endDate = startDate;
    } else if (_viewMode == 'range' &&
        _rangeStart != null &&
        _rangeEnd != null) {
      startDate = _formatDate(_rangeStart!);
      endDate = _formatDate(_rangeEnd!);
    } else {
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await ApiService.markNoBowelBatch(startDate, endDate);

      if (mounted) Navigator.pop(context);

      await _loadDailyCounts();
      await _loadRecords(refresh: true);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result['message'] ?? '批量标注完成')));
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '批量标注失败: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _unmarkNoBowelForSelection() async {
    String startDate;
    String endDate;

    if (_viewMode == 'single' && _selectedDate != null) {
      startDate = _formatDate(_selectedDate!);
      endDate = startDate;
    } else if (_viewMode == 'range' &&
        _rangeStart != null &&
        _rangeEnd != null) {
      startDate = _formatDate(_rangeStart!);
      endDate = _formatDate(_rangeEnd!);
    } else {
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await ApiService.unmarkNoBowelBatch(startDate, endDate);

      if (mounted) Navigator.pop(context);

      await _loadDailyCounts();
      await _loadRecords(refresh: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? '批量取消标注完成')),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '批量取消标注失败: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
