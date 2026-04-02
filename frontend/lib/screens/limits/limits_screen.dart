import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/formatters.dart';
import '../../providers/limit_provider.dart';
import '../../providers/record_provider.dart';

class LimitsScreen extends StatefulWidget {
  const LimitsScreen({super.key});

  @override
  State<LimitsScreen> createState() => _LimitsScreenState();
}

class _LimitsScreenState extends State<LimitsScreen> {
  late TextEditingController dailyController;

  @override
  void initState() {
    super.initState();
    dailyController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    final limitProvider = context.watch<LimitProvider>();
    final recordProvider = context.watch<RecordProvider>();
    dailyController.text = limitProvider.config.dailyLimit.toStringAsFixed(0);
    return Scaffold(
      appBar: AppBar(title: const Text('限额设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
              controller: dailyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '每日限额')),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [200, 250, 300, 500]
                .map((value) => ActionChip(
                    label: Text('¥$value'),
                    onPressed: () => context
                        .read<LimitProvider>()
                        .updateDailyLimit(value.toDouble())))
                .toList(),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              title: const Text('月度限额'),
              subtitle: const Text('按 30 天自动计算'),
              trailing: Text(
                  AppFormatters.currency(limitProvider.config.monthlyLimit)),
            ),
          ),
          const SizedBox(height: 16),
          Text('分类限额', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...limitProvider.config.categoryLimits.entries.map((entry) {
            final spent = recordProvider.spentForCategoryToday(entry.key);
            final double ratio = entry.value == 0
                ? 0.0
                : (spent / entry.value).clamp(0, 1).toDouble();
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(entry.key)),
                        Text(AppFormatters.currency(entry.value)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                        value: ratio,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(8)),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context
                .read<LimitProvider>()
                .updateDailyLimit(double.tryParse(dailyController.text) ?? 250),
            child: const Text('保存限额设置'),
          )
        ],
      ),
    );
  }
}
