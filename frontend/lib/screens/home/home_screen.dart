import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../providers/limit_provider.dart';
import '../../providers/record_provider.dart';
import '../../screens/limits/limits_screen.dart';
import '../../screens/records/records_screen.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/summary_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Color _statusColor(double remainingRate) {
    if (remainingRate < 0) return AppColors.danger;
    if (remainingRate < .2) return AppColors.danger;
    if (remainingRate < .5) return AppColors.warning;
    return AppColors.safe;
  }

  String _statusText(double remainingRate, double remaining) {
    if (remainingRate < 0) return '🚫 今日已超支 ${AppFormatters.currency(remaining.abs())}';
    if (remainingRate < .2) return '⚠️ 今日预算即将用完';
    if (remainingRate < .5) return '今日预算已用 50%，请注意控制';
    return '今日预算充足，继续保持';
  }

  @override
  Widget build(BuildContext context) {
    final recordProvider = context.watch<RecordProvider>();
    final limitProvider = context.watch<LimitProvider>();
    final spent = recordProvider.todaySpent;
    final limit = limitProvider.config.dailyLimit;
    final remaining = limit - spent;
    final remainingRate = limit == 0 ? 0.0 : remaining / limit;
    final barColor = _statusColor(remainingRate);
    final recent = recordProvider.records.take(4).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('首页'),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LimitsScreen())),
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LimitsScreen())),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [barColor.withOpacity(.16), Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('今日剩余额度'),
                  const SizedBox(height: 12),
                  Text(
                    AppFormatters.currency(remaining),
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: remaining < 0 ? AppColors.danger : AppColors.text,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: limit == 0 ? 0 : (spent / limit).clamp(0, 1),
                    minHeight: 12,
                    borderRadius: BorderRadius.circular(8),
                    color: barColor,
                    backgroundColor: Colors.black12,
                  ),
                  const SizedBox(height: 12),
                  Text('今日限额：${AppFormatters.currency(limit)} · 已消费：${AppFormatters.currency(spent)}'),
                  const SizedBox(height: 12),
                  StatusBadge(text: _statusText(remainingRate, remaining), color: barColor),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('快捷记账', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const ['早餐', '午餐', '晚餐', '交通', '购物', '娱乐']
                .map((e) => ActionChip(label: Text(e), onPressed: null))
                .toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: SummaryCard(title: '已消费', value: AppFormatters.currency(spent), icon: Icons.payments_outlined)),
              Expanded(child: SummaryCard(title: '预算剩余', value: AppFormatters.currency(remaining), icon: Icons.account_balance_wallet_outlined)),
            ],
          ),
          const SizedBox(height: 8),
          SummaryCard(title: '今日记账', value: '${recordProvider.todayCount} 笔', icon: Icons.receipt_long_outlined),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('最近记录', style: Theme.of(context).textTheme.titleMedium),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecordsScreen())),
                child: const Text('查看全部'),
              )
            ],
          ),
          if (recent.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(24), child: Center(child: Text('还没有消费记录，记第一笔吧'))))
          else
            ...recent.map(
              (e) => Card(
                child: ListTile(
                  title: Text(e.category),
                  subtitle: Text(e.note.isEmpty ? AppFormatters.dateTime(e.time) : '${e.note} · ${AppFormatters.dateTime(e.time)}'),
                  trailing: Text(AppFormatters.currency(e.amount)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
