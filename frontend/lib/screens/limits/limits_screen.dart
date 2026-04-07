import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/formatters.dart';
import '../../models/limit_config.dart';
import '../../providers/limit_provider.dart';
import '../../providers/record_provider.dart';

class LimitsScreen extends StatefulWidget {
  const LimitsScreen({super.key});

  @override
  State<LimitsScreen> createState() => _LimitsScreenState();
}

class _LimitsScreenState extends State<LimitsScreen> {
  late TextEditingController dailyController;
  bool _initialized = false;
  bool _dirty = false;
  late LimitConfig _draft;

  String _normalizeCategoryName(String value) {
    return value.trim().toLowerCase();
  }

  bool _isSameConfig(LimitConfig a, LimitConfig b) {
    return a.toJson().toString() == b.toJson().toString();
  }

  void _syncFromProvider(LimitConfig source) {
    _draft = source.copy();
    dailyController.text = _draft.dailyLimit.toStringAsFixed(0);
    _dirty = false;
  }

  void _markDirty(LimitProvider limitProvider) {
    _draft = limitProvider.normalizeConfig(_draft);
    dailyController.text = _draft.dailyLimit.toStringAsFixed(0);
    _dirty = !_isSameConfig(_draft, limitProvider.config);
  }

  Future<void> _addCategoryLimit(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    var cycle = LimitCycle.daily;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('新增分类限额'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: '分类名称'),
              ),
              const SizedBox(height: 12),
              SegmentedButton<LimitCycle>(
                segments: const [
                  ButtonSegment(value: LimitCycle.daily, label: Text('日限额')),
                  ButtonSegment(value: LimitCycle.monthly, label: Text('月限额')),
                ],
                selected: {cycle},
                onSelectionChanged: (selection) {
                  setDialogState(() => cycle = selection.first);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: cycle == LimitCycle.daily ? '日限额' : '月限额',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
                if (name.isEmpty || amount <= 0) {
                  return;
                }
                Navigator.of(context).pop({
                  'name': name,
                  'cycle': cycle,
                  'amount': amount,
                });
              },
              child: const Text('新增'),
            ),
          ],
        ),
      ),
    );

    if (!context.mounted || result == null) {
      return;
    }

    final name = (result['name'] as String).trim();
    if (name.isEmpty) {
      return;
    }
    final normalizedName = _normalizeCategoryName(name);
    final exists = _draft.categoryLimits.keys.any(
      (key) => _normalizeCategoryName(key) == normalizedName,
    );
    if (exists) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('该分类已存在')));
      return;
    }

    final selectedCycle = result['cycle'] as LimitCycle;
    final amount = (result['amount'] as num).toDouble();
    setState(() {
      _draft.categoryLimits[name] = CategoryLimitSetting(
        cycle: selectedCycle,
        dailyLimit: selectedCycle == LimitCycle.daily ? amount : 0,
        monthlyLimit: selectedCycle == LimitCycle.monthly ? amount : 0,
      );
      _markDirty(context.read<LimitProvider>());
    });
  }

  Future<void> _editCategoryLimit(BuildContext context, String category,
      CategoryLimitSetting value) async {
    final amountCtrl = TextEditingController(
      text: value.selectedAmount > 0 ? value.selectedAmount.toStringAsFixed(0) : '',
    );
    var selectedCycle = value.cycle;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('设置$category限额'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<LimitCycle>(
                segments: const [
                  ButtonSegment(value: LimitCycle.daily, label: Text('日限额')),
                  ButtonSegment(value: LimitCycle.monthly, label: Text('月限额')),
                ],
                selected: {selectedCycle},
                onSelectionChanged: (selection) {
                  setDialogState(() {
                    selectedCycle = selection.first;
                    final selectedAmount =
                        selectedCycle == LimitCycle.daily ? value.dailyLimit : value.monthlyLimit;
                    amountCtrl.text = selectedAmount > 0
                        ? selectedAmount.toStringAsFixed(0)
                        : '';
                  });
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: selectedCycle == LimitCycle.daily ? '日限额' : '月限额',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop({'delete': true}),
              child: const Text('删除分类'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
                if (amount <= 0) {
                  return;
                }
                Navigator.of(context).pop(
                  {'delete': false, 'cycle': selectedCycle, 'amount': amount},
                );
              },
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );

    if (!context.mounted || result == null) {
      return;
    }

    setState(() {
      if (result['delete'] == true) {
        _draft.categoryLimits.remove(category);
      } else {
        final cycle = result['cycle'] as LimitCycle;
        final amount = (result['amount'] as num).toDouble();
        final current = _draft.categoryLimits[category] ?? CategoryLimitSetting.daily(0);
        _draft.categoryLimits[category] = CategoryLimitSetting(
          cycle: cycle,
          dailyLimit: cycle == LimitCycle.daily ? amount : current.dailyLimit,
          monthlyLimit: cycle == LimitCycle.monthly ? amount : current.monthlyLimit,
        );
      }
      _markDirty(context.read<LimitProvider>());
    });
  }

  @override
  void initState() {
    super.initState();
    dailyController = TextEditingController();
  }

  @override
  void dispose() {
    dailyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final limitProvider = context.watch<LimitProvider>();
    final recordProvider = context.watch<RecordProvider>();
    if (!_initialized) {
      _syncFromProvider(limitProvider.config);
      _initialized = true;
    } else if (!_dirty && !_isSameConfig(_draft, limitProvider.config)) {
      _syncFromProvider(limitProvider.config);
    }

    final now = DateTime.now();
    final monthDays = limitProvider.daysOfMonth(now);
    final monthlyCategorySum = _draft.categoryLimits.values
        .where((e) => e.cycle == LimitCycle.monthly)
        .fold<double>(0, (sum, item) => sum + item.monthlyLimit);
    final monthlyComputed = limitProvider.computeMonthlyTotal(
      dailyLimit: _draft.dailyLimit,
      monthlyCategoryLimit: monthlyCategorySum,
      month: now,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('限额设置')),
      bottomNavigationBar: _dirty
          ? SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: FilledButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final provider = context.read<LimitProvider>();
                  final daily = double.tryParse(dailyController.text.trim()) ?? 0;
                  setState(() {
                    _draft.dailyLimit = daily;
                    _markDirty(provider);
                  });
                  await provider.saveConfig(_draft);
                  if (!mounted) {
                    return;
                  }
                  setState(() {
                    _dirty = false;
                    _syncFromProvider(provider.config);
                  });
                  messenger.showSnackBar(const SnackBar(content: Text('限额设置已保存')));
                },
                child: const Text('保存限额设置'),
              ),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: dailyController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: '每日限额（餐饮）'),
            onChanged: (value) {
              setState(() {
                _draft.dailyLimit = double.tryParse(value) ?? 0;
                final currentFood = _draft.categoryLimits[LimitProvider.dailyBudgetCategory] ??
                    CategoryLimitSetting.daily(0);
                _draft.categoryLimits[LimitProvider.dailyBudgetCategory] = CategoryLimitSetting(
                  cycle: LimitCycle.daily,
                  dailyLimit: _draft.dailyLimit,
                  monthlyLimit: currentFood.monthlyLimit,
                );
                _markDirty(limitProvider);
              });
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [200, 250, 300, 500]
                .map((value) => ActionChip(
                    label: Text('¥$value'),
                    onPressed: () {
                      setState(() {
                        _draft.dailyLimit = value.toDouble();
                        final currentFood =
                            _draft.categoryLimits[LimitProvider.dailyBudgetCategory] ??
                                CategoryLimitSetting.daily(0);
                        _draft.categoryLimits[LimitProvider.dailyBudgetCategory] =
                            CategoryLimitSetting(
                          cycle: LimitCycle.daily,
                          dailyLimit: _draft.dailyLimit,
                          monthlyLimit: currentFood.monthlyLimit,
                        );
                        dailyController.text = value.toString();
                        _markDirty(limitProvider);
                      });
                    }))
                .toList(),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              title: const Text('月度限额'),
              subtitle: Text('按本月天数计算（$monthDays 天）'),
              trailing: Text(AppFormatters.currency(monthlyComputed)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text('分类限额', style: Theme.of(context).textTheme.titleMedium),
              ),
              TextButton.icon(
                onPressed: () => _addCategoryLimit(context),
                icon: const Icon(Icons.add),
                label: const Text('新增分类'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._draft.categoryLimits.entries.map((entry) {
            final isDaily = entry.value.cycle == LimitCycle.daily;
            final amount = entry.value.selectedAmount;
            final spent = isDaily
                ? recordProvider.spentForCategoryToday(entry.key)
                : recordProvider.spentForCategoryMonth(entry.key, now);
            final double ratio = amount == 0
                ? 0.0
                : (spent / amount).clamp(0, 1).toDouble();
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(entry.key)),
                        Text('${isDaily ? '日' : '月'} ${AppFormatters.currency(amount)}'),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () =>
                              _editCategoryLimit(context, entry.key, entry.value),
                        ),
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
          if (_dirty) const SizedBox(height: 84),
        ],
      ),
    );
  }
}
