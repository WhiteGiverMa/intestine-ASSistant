import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/models.dart';
import '../theme/theme_colors.dart';
import '../theme/theme_decorations.dart';

class TrendChart extends StatelessWidget {
  final StatsTrends? trends;
  final ThemeColors colors;

  const TrendChart({super.key, required this.trends, required this.colors});

  @override
  Widget build(BuildContext context) {
    if (trends == null || trends!.trends.isEmpty) {
      return const SizedBox.shrink();
    }

    final trendsList = trends!.trends;
    double maxY = 0;
    for (final t in trendsList) {
      if (t.value > maxY) maxY = t.value.toDouble();
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < trendsList.length; i++) {
      final value =
          trendsList[i].isRecorded ? trendsList[i].value.toDouble() : 0.0;
      spots.add(FlSpot(i.toDouble(), value));
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: ThemeDecorations.card(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '排便频率趋势',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colors.card,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.primary, width: 2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '已记录',
                    style: TextStyle(fontSize: 10, color: colors.textSecondary),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colors.surfaceVariant,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.divider),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '未记录',
                    style: TextStyle(fontSize: 10, color: colors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: maxY > 0 ? (maxY / 4).ceilToDouble() : 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: colors.divider, strokeWidth: 1);
                  },
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(),
                  topTitles: const AxisTitles(),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: maxY > 0 ? (maxY / 4).ceilToDouble() : 1,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            fontSize: 10,
                            color: colors.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: (trendsList.length / 5).ceilToDouble(),
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= trendsList.length) {
                          return const Text('');
                        }
                        final date = trendsList[idx].date;
                        final parts = date.split('-');
                        if (parts.length >= 3) {
                          return Text(
                            '${parts[1]}/${parts[2]}',
                            style: TextStyle(
                              fontSize: 9,
                              color: colors.textSecondary,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (trendsList.length - 1).toDouble(),
                minY: 0,
                maxY: maxY > 0 ? maxY + 1 : 4,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.15,
                    color: colors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      getDotPainter: (spot, percent, barData, index) {
                        final t = trendsList[index];
                        if (t.isRecorded) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: colors.card,
                            strokeWidth: 2,
                            strokeColor: colors.primary,
                          );
                        } else {
                          return FlDotCirclePainter(
                            radius: 3,
                            color: colors.surfaceVariant,
                            strokeWidth: 1,
                            strokeColor: colors.divider,
                          );
                        }
                      },
                    ),
                    belowBarData: BarAreaData(
                      color: colors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => colors.card,
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    tooltipMargin: 8,
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final idx = spot.x.toInt();
                        if (idx < 0 || idx >= trendsList.length) {
                          return null;
                        }

                        final t = trendsList[idx];
                        final value = t.isRecorded ? t.value : 0;

                        return LineTooltipItem(
                          '$value次',
                          TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color:
                                t.isRecorded
                                    ? colors.primary
                                    : colors.textSecondary,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StoolTypePieChart extends StatefulWidget {
  final StatsSummary? summary;
  final ThemeColors colors;

  const StoolTypePieChart({
    super.key,
    required this.summary,
    required this.colors,
  });

  @override
  State<StoolTypePieChart> createState() => _StoolTypePieChartState();
}

class _StoolTypePieChartState extends State<StoolTypePieChart> {
  int _selectedPieSection = -1;

  static const _chartColors = [
    Color(0xFF8B4513),
    Color(0xFFD2691E),
    Color(0xFFCD853F),
    Color(0xFFDEB887),
    Color(0xFFF4A460),
    Color(0xFFDAA520),
    Color(0xFFB8860B),
  ];

  @override
  Widget build(BuildContext context) {
    if (widget.summary == null) return const SizedBox.shrink();

    final distribution = widget.summary!.stoolTypeDistribution;
    final total = distribution.values.fold(0, (sum, v) => sum + v);
    if (total == 0) return const SizedBox.shrink();

    final sections = <PieChartSectionData>[];
    final sortedEntries =
        distribution.entries.toList()
          ..sort((a, b) => int.parse(a.key).compareTo(int.parse(b.key)));

    for (final entry in sortedEntries) {
      final typeNum = int.parse(entry.key);
      final percentage = (entry.value / total * 100).round();
      final isTouched = _selectedPieSection == typeNum;

      sections.add(
        PieChartSectionData(
          value: entry.value.toDouble(),
          color: _chartColors[typeNum - 1],
          title: '$percentage%',
          radius: isTouched ? 50 : 40,
          titleStyle: TextStyle(
            fontSize: isTouched ? 14 : 11,
            fontWeight: FontWeight.bold,
            color: widget.colors.textOnPrimary,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ThemeDecorations.card(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '形态分布',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: widget.colors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 150,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 25,
                sectionsSpace: 2,
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    if (!event.isInterestedForInteractions ||
                        response == null ||
                        response.touchedSection == null) {
                      setState(() => _selectedPieSection = -1);
                      return;
                    }
                    final touchedIndex =
                        response.touchedSection!.touchedSectionIndex;
                    if (touchedIndex >= 0 &&
                        touchedIndex < sortedEntries.length) {
                      setState(
                        () =>
                            _selectedPieSection = int.parse(
                              sortedEntries[touchedIndex].key,
                            ),
                      );
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children:
                sortedEntries.map((entry) {
                  final typeNum = int.parse(entry.key);
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _chartColors[typeNum - 1],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'T$typeNum',
                        style: TextStyle(
                          fontSize: 10,
                          color: widget.colors.textSecondary,
                        ),
                      ),
                    ],
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }
}

class TimeDistributionRing extends StatelessWidget {
  final StatsSummary? summary;
  final ThemeColors colors;

  const TimeDistributionRing({
    super.key,
    required this.summary,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    if (summary == null) return const SizedBox.shrink();

    final time = summary!.timeDistribution;
    final total = time.morning + time.afternoon + time.evening;
    if (total == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ThemeDecorations.card(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '时间分布',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        value: time.morning.toDouble(),
                        color: Colors.orange,
                        title: '',
                        radius: 40,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: time.afternoon.toDouble(),
                        color: Colors.amber,
                        title: '',
                        radius: 40,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: time.evening.toDouble(),
                        color: Colors.indigo,
                        title: '',
                        radius: 40,
                        showTitle: false,
                      ),
                    ],
                    centerSpaceRadius: 30,
                    sectionsSpace: 2,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$total',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                    Text(
                      '次',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTimeLegend('🌅', '早', time.morning, Colors.orange),
              _buildTimeLegend('☀️', '午', time.afternoon, Colors.amber),
              _buildTimeLegend('🌙', '晚', time.evening, Colors.indigo),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeLegend(String emoji, String label, int count, Color color) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 2),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: colors.textSecondary),
        ),
      ],
    );
  }
}

class StatsGrid extends StatelessWidget {
  final StatsSummary? summary;
  final ThemeColors colors;

  const StatsGrid({super.key, required this.summary, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            emoji: '📊',
            value: '${summary?.totalRecords ?? 0}',
            label: '记录次数',
            color: colors.primary,
            colors: colors,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            emoji: '📈',
            value: (summary?.avgFrequencyPerDay ?? 0).toStringAsFixed(1),
            label: '日均次数',
            color: const Color(0xFF1976D2),
            colors: colors,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            emoji: '⏱️',
            value: (summary?.avgDurationMinutes ?? 0).toStringAsFixed(1),
            label: '平均时长(分)',
            color: const Color(0xFF7B1FA2),
            colors: colors,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final Color color;
  final ThemeColors colors;

  const _StatCard({
    required this.emoji,
    required this.value,
    required this.label,
    required this.color,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ThemeDecorations.card(context),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
