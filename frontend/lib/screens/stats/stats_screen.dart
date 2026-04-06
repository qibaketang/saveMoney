import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/formatters.dart';
import '../../providers/record_provider.dart';
import '../../services/api_client.dart';
import '../../services/stats_api.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  DateTime _selectedMonth =
      DateTime(DateTime.now().year, DateTime.now().month, 1);
  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _loadStats();
  }

  Future<Map<String, dynamic>> _loadStats() {
    return StatsApi().monthly(
      year: _selectedMonth.year,
      month: _selectedMonth.month,
    );
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month + delta, 1);
      _statsFuture = _loadStats();
    });
  }

  Map<String, dynamic> _buildLocalStats(RecordProvider provider) {
    final daily = provider.dailySpendForMonth(_selectedMonth);
    final dailyTrend = <Map<String, dynamic>>[];
    for (int i = 0; i < daily.length; i++) {
      if (daily[i] > 0) {
        dailyTrend.add({'_id': i + 1, 'total': daily[i]});
      }
    }

    final categoryStats = provider
        .categorySpendForMonth(_selectedMonth)
        .entries
        .map((e) => {'_id': e.key, 'total': e.value})
        .toList();

    return {
      'dailyTrend': dailyTrend,
      'categoryStats': categoryStats,
    };
  }

  @override
  Widget build(BuildContext context) {
    final recordProvider = context.watch<RecordProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('统计分析')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final hasApiError = snapshot.hasError;
          final apiData = snapshot.data ?? const <String, dynamic>{};
          final apiTrend = (apiData['dailyTrend'] as List? ?? const []);
          final apiCategories = (apiData['categoryStats'] as List? ?? const []);
          final useLocalFallback =
              hasApiError || (apiTrend.isEmpty && apiCategories.isEmpty);
          final data =
              useLocalFallback ? _buildLocalStats(recordProvider) : apiData;
          final trend = (data['dailyTrend'] as List? ?? const [])
              .whereType<Map<String, dynamic>>()
              .toList();
          final days = DateUtils.getDaysInMonth(
              _selectedMonth.year, _selectedMonth.month);
          final daily = List<double>.filled(days, 0);
          for (final row in trend) {
            final day = (row['_id'] as num?)?.toInt() ?? 0;
            final total = (row['total'] as num?)?.toDouble() ?? 0;
            if (day >= 1 && day <= days) {
              daily[day - 1] = total;
            }
          }

          final categories = (data['categoryStats'] as List? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map((row) => MapEntry(
                    (row['_id'] ?? '未分类').toString(),
                    (row['total'] as num?)?.toDouble() ?? 0,
                  ))
              .toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          final monthLabel =
              '${_selectedMonth.year.toString().padLeft(4, '0')}-${_selectedMonth.month.toString().padLeft(2, '0')}';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => _changeMonth(-1),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Expanded(
                        child: Text(
                          monthLabel,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _changeMonth(1),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('月度消费趋势',
                          style: Theme.of(context).textTheme.titleMedium),
                      if (useLocalFallback)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text('当前显示本地统计数据',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.black54)),
                        ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 220,
                        child: LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: false),
                            titlesData: const FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                    showTitles: true, reservedSize: 36),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                isCurved: true,
                                spots: [
                                  for (int i = 0; i < daily.length; i++)
                                    FlSpot(i.toDouble() + 1, daily[i])
                                ],
                                dotData: const FlDotData(show: false),
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('分类支出排行',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      if (categories.isEmpty)
                        const Text('本月还没有记录')
                      else
                        ...categories.map(
                          (entry) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(entry.key),
                            trailing: Text(AppFormatters.currency(entry.value)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
