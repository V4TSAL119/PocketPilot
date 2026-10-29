import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../database/app_database.dart';
import '../services/currency_service.dart';
import '../utils/app_theme.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _isLoading = true;
  int _spentTodayPaise = 0;
  int _spentThisWeekPaise = 0;
  int _spentThisMonthPaise = 0;
  int _totalMoneyPaise = 0;
  int _totalExpensesPaise = 0;
  List<Map<String, dynamic>> _categoryBreakdown = [];
  List<Map<String, dynamic>> _monthlySpending = [];
  int _touchedPieIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();

      // Today
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
      final spentToday = await AppDatabase.instance.getTotalExpensesPaise(
        startDate: todayStart,
        endDate: todayEnd,
      );

      // This Week
      final daysFromMonday = (now.weekday - 1);
      final monday = now.subtract(Duration(days: daysFromMonday));
      final weekStart = DateTime(monday.year, monday.month, monday.day);
      final weekEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
      final spentThisWeek = await AppDatabase.instance.getTotalExpensesPaise(
        startDate: weekStart,
        endDate: weekEnd,
      );

      // This Month
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      final spentThisMonth = await AppDatabase.instance.getTotalExpensesPaise(
        startDate: monthStart,
        endDate: monthEnd,
      );

      // Overall Overview
      final overview = await AppDatabase.instance.getFinancialOverview();
      final totalMoney = overview['total_money'] ?? 0;
      final totalExpenses = overview['total_expenses'] ?? 0;

      // Category breakdown (All Time)
      final breakdown = await AppDatabase.instance.getCategorySpendingBreakdown();

      // Monthly spending (last 6 months)
      final monthly = await AppDatabase.instance.getMonthlySpending(monthsBack: 6);

      if (mounted) {
        setState(() {
          _spentTodayPaise = spentToday;
          _spentThisWeekPaise = spentThisWeek;
          _spentThisMonthPaise = spentThisMonth;
          _totalMoneyPaise = totalMoney;
          _totalExpensesPaise = totalExpenses;
          _categoryBreakdown = breakdown;
          _monthlySpending = monthly;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }

    final highestCategory = _categoryBreakdown.isNotEmpty
        ? _categoryBreakdown.first['category_name'] as String
        : 'None';
    final highestCategoryPaise = _categoryBreakdown.isNotEmpty
        ? _categoryBreakdown.first['total_paise'] as int
        : 0;

    final remainingPercentage = _totalMoneyPaise > 0
        ? (((_totalMoneyPaise - _totalExpensesPaise) / _totalMoneyPaise) * 100.0)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spending Analytics'),
        actions: [
          IconButton(
            tooltip: 'Refresh Analytics',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.accentColor,
        backgroundColor: AppTheme.card,
        onRefresh: _loadAnalytics,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period Spending Cards (Today, Week, Month)
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      label: 'Today',
                      amountPaise: _spentTodayPaise,
                      color: AppTheme.tastefulRed,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricCard(
                      label: 'This Week',
                      amountPaise: _spentThisWeekPaise,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricCard(
                      label: 'This Month',
                      amountPaise: _spentThisMonthPaise,
                      color: const Color(0xFF3B82F6),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Highlights row (Highest Spending Category & Remaining %)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Highest Expense Category',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            highestCategory,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            CurrencyService.formatPaise(highestCategoryPaise),
                            style: TextStyle(
                              color: AppTheme.tastefulRed,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Remaining Budget %',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _totalMoneyPaise > 0
                                ? '${remainingPercentage.toStringAsFixed(1)}%'
                                : 'No Budget',
                            style: TextStyle(
                              color: remainingPercentage > 0
                                  ? AppTheme.emeraldGreen
                                  : AppTheme.tastefulRed,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            CurrencyService.formatPaise(
                              _totalMoneyPaise - _totalExpensesPaise,
                            ),
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Category-wise Breakdown with Donut Chart
              Text(
                'Spending by Category',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: _categoryBreakdown.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 30),
                        child: Center(
                          child: Text(
                            'No expense data to display in chart',
                            style: TextStyle(color: AppTheme.textMuted),
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          SizedBox(
                            height: 200,
                            child: PieChart(
                              PieChartData(
                                pieTouchData: PieTouchData(
                                  touchCallback: (event, pieTouchResponse) {
                                    setState(() {
                                      if (!event.isInterestedForInteractions ||
                                          pieTouchResponse == null ||
                                          pieTouchResponse.touchedSection == null) {
                                        _touchedPieIndex = -1;
                                        return;
                                      }
                                      _touchedPieIndex = pieTouchResponse
                                          .touchedSection!.touchedSectionIndex;
                                    });
                                  },
                                ),
                                borderData: FlBorderData(show: false),
                                sectionsSpace: 2,
                                centerSpaceRadius: 46,
                                sections: _generatePieSections(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Divider(color: AppTheme.borderSubtle),
                          const SizedBox(height: 12),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _categoryBreakdown.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final item = _categoryBreakdown[index];
                              final color = Color(item['category_color_value'] as int);
                              final name = item['category_name'] as String;
                              final totalPaise = item['total_paise'] as int;
                              final percent = _totalExpensesPaise > 0
                                  ? (totalPaise / _totalExpensesPaise) * 100
                                  : 0.0;

                              return Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${percent.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    CurrencyService.formatPaise(totalPaise),
                                    style: TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 24),

              // Monthly Spending Bar Chart
              Text(
                'Monthly Spending Trend (Last 6 Months)',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: SizedBox(
                  height: 220,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _calculateMaxBarY(),
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => AppTheme.surfaceSecondary,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final month = _monthlySpending[groupIndex]['month_date'] as DateTime;
                            final amount = CurrencyService.formatPaise(
                              (_monthlySpending[groupIndex]['total_paise'] as int),
                            );
                            return BarTooltipItem(
                              '${DateFormat('MMM yyyy').format(month)}\n$amount',
                              TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= _monthlySpending.length) {
                                return const SizedBox.shrink();
                              }
                              final month = _monthlySpending[index]['month_date'] as DateTime;
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  DateFormat('MMM').format(month),
                                  style: TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 42,
                            getTitlesWidget: (value, meta) {
                              if (value == 0) return const SizedBox.shrink();
                              return Text(
                                '₹${(value / 1000).toStringAsFixed(0)}k',
                                style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 10,
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: AppTheme.borderSubtle,
                          strokeWidth: 0.8,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: _generateBarGroups(),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required int amountPaise,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              CurrencyService.formatPaise(amountPaise),
              style: TextStyle(
                color: amountPaise > 0 ? color : AppTheme.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _generatePieSections() {
    return _categoryBreakdown.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final isTouched = index == _touchedPieIndex;
      final radius = isTouched ? 48.0 : 40.0;
      final color = Color(item['category_color_value'] as int);
      final totalPaise = item['total_paise'] as int;

      final percent = _totalExpensesPaise > 0
          ? ((totalPaise / _totalExpensesPaise) * 100)
          : 0.0;

      return PieChartSectionData(
        color: color,
        value: totalPaise.toDouble(),
        title: isTouched ? '${percent.toStringAsFixed(0)}%' : '',
        radius: radius,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  double _calculateMaxBarY() {
    double maxAmount = 1000.0; // Default min scale (₹1000)
    for (final m in _monthlySpending) {
      final rupees = (m['total_paise'] as int) / 100.0;
      if (rupees > maxAmount) {
        maxAmount = rupees;
      }
    }
    return maxAmount * 1.25; // 25% padding headroom
  }

  List<BarChartGroupData> _generateBarGroups() {
    return _monthlySpending.asMap().entries.map((entry) {
      final index = entry.key;
      final m = entry.value;
      final rupees = (m['total_paise'] as int) / 100.0;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: rupees,
            color: rupees > 0 ? AppTheme.accentColor : AppTheme.surfaceSecondary,
            width: 18,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
      );
    }).toList();
  }
}
