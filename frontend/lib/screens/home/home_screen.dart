import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/expense_record.dart';
import '../../models/limit_config.dart';
import '../../providers/limit_provider.dart';
import '../../providers/record_provider.dart';
import '../../providers/settings_provider.dart';
import '../../screens/limits/limits_screen.dart';
import '../../screens/records/records_screen.dart';
import '../../widgets/status_badge.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const int _recentPageSize = 5;
  final ScrollController _contentScrollController = ScrollController();
  final ScrollController _quickActionsScrollController = ScrollController();
  late DateTime _selectedDate;
  int _visibleRecentCount = _recentPageSize;

  @override
  void initState() {
    super.initState();
    _selectedDate = _today();
    _contentScrollController.addListener(_onContentScroll);
  }

  @override
  void dispose() {
    _contentScrollController
      ..removeListener(_onContentScroll)
      ..dispose();
    _quickActionsScrollController.dispose();
    super.dispose();
  }

  void _onQuickActionsPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent ||
        !_quickActionsScrollController.hasClients) {
      return;
    }
    final position = _quickActionsScrollController.position;
    final delta =
        event.scrollDelta.dx == 0 ? event.scrollDelta.dy : event.scrollDelta.dx;
    final nextOffset = (position.pixels + delta)
        .clamp(position.minScrollExtent, position.maxScrollExtent);
    _quickActionsScrollController.jumpTo(nextOffset);
  }

  void _onContentScroll() {
    if (!_contentScrollController.hasClients) {
      return;
    }
    final position = _contentScrollController.position;
    if (position.pixels >= position.maxScrollExtent - 80) {
      final date = _selectedDate;
      final total = context
          .read<RecordProvider>()
          .records
          .where((e) => _isSameDay(e.time, date))
          .length;
      if (_visibleRecentCount < total) {
        setState(() {
          _visibleRecentCount =
              (_visibleRecentCount + _recentPageSize).clamp(0, total);
        });
      }
    }
  }

  void _changeDate(int deltaDays) {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day + deltaDays,
      );
      _visibleRecentCount = _recentPageSize;
    });
  }

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  int _sortCategoryEntries(
    MapEntry<String, CategoryLimitSetting> a,
    MapEntry<String, CategoryLimitSetting> b,
  ) {
    if (a.value.cycle != b.value.cycle) {
      return a.value.cycle == LimitCycle.daily ? -1 : 1;
    }

    if (a.value.cycle == LimitCycle.daily) {
      final aIsFood = a.key == '餐饮';
      final bIsFood = b.key == '餐饮';
      if (aIsFood != bIsFood) {
        return aIsFood ? -1 : 1;
      }
    }

    return a.key.compareTo(b.key);
  }

  IconData _iconForCategory(String category) {
    switch (category) {
      case '早餐':
        return Icons.free_breakfast_outlined;
      case '午餐':
        return Icons.lunch_dining_outlined;
      case '晚餐':
        return Icons.dinner_dining_outlined;
      case '交通':
        return Icons.directions_bus_filled_outlined;
      case '购物':
        return Icons.shopping_bag_outlined;
      case '餐饮':
        return Icons.restaurant_outlined;
      case '住房':
        return Icons.home_outlined;
      case '医疗':
        return Icons.medical_services_outlined;
      case '教育':
        return Icons.school_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  Future<void> _showQuickActionsEditor(BuildContext context) async {
    final settings = context.read<SettingsProvider>();
    final draft = List<String>.from(settings.quickLedgerCategories);
    final inputController = TextEditingController();

    final shouldSave = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 8,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('自定义快捷记账',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('最多 8 个，至少保留 1 个',
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: draft
                          .map((item) => Chip(
                                label: Text(item),
                                onDeleted: draft.length <= 1
                                    ? null
                                    : () {
                                        setSheetState(() {
                                          draft.remove(item);
                                        });
                                      },
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: inputController,
                            decoration:
                                const InputDecoration(labelText: '新增选项'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.tonal(
                          onPressed: () {
                            final text = inputController.text.trim();
                            if (text.isEmpty) {
                              return;
                            }
                            if (draft.contains(text)) {
                              return;
                            }
                            if (draft.length >= 8) {
                              return;
                            }
                            setSheetState(() {
                              draft.add(text);
                              inputController.clear();
                            });
                          },
                          child: const Text('添加'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('保存快捷选项'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (shouldSave != true || !context.mounted) {
      return;
    }
    await settings.update(quickLedgerCategoriesValue: draft);
  }

  String _normalizeBudgetCategory(String category) {
    if (category == '早餐' || category == '午餐' || category == '晚餐') {
      return '餐饮';
    }
    return category;
  }

  Future<void> _quickAddRecord(BuildContext context, String category) async {
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('快捷记账 · $category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: '金额'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: '备注（可选）'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final amount = double.tryParse(amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效金额')),
      );
      return;
    }

    final budgetCategory = _normalizeBudgetCategory(category);
    await context.read<RecordProvider>().addRecord(
          category: budgetCategory,
          amount: amount,
          note: noteController.text.trim(),
          time: DateTime.now(),
        );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('快捷记账成功')));
  }

  void _showCategoryRecordsSheet({
    required BuildContext context,
    required String category,
    required LimitCycle cycle,
    required DateTime date,
    required List<ExpenseRecord> records,
    required double spent,
    required double limit,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * .72,
            child: Column(
              children: [
                ListTile(
                  title: Text('$category记账情况'),
                  subtitle: Text(
                    cycle == LimitCycle.daily
                        ? '日期：${AppFormatters.date(date)}'
                        : '月份：${date.year}-${date.month.toString().padLeft(2, '0')}',
                  ),
                  trailing: Text(
                      '${AppFormatters.currency(spent)} / ${AppFormatters.currency(limit)}'),
                ),
                const Divider(height: 1),
                Expanded(
                  child: records.isEmpty
                      ? const Center(child: Text('暂无该分类记录'))
                      : ListView.builder(
                          itemCount: records.length,
                          itemBuilder: (context, index) {
                            final item = records[index];
                            return ListTile(
                              title: Text(
                                  item.note.isEmpty ? category : item.note),
                              subtitle: Text(AppFormatters.dateTime(item.time)),
                              trailing:
                                  Text(AppFormatters.currency(item.amount)),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _statusColor(double remainingRate) {
    if (remainingRate < 0) return AppColors.danger;
    if (remainingRate < .2) return AppColors.danger;
    if (remainingRate < .5) return AppColors.warning;
    return AppColors.safe;
  }

  String _statusText(double remainingRate, double remaining) {
    if (remainingRate < 0)
      return '🚫 今日已超支 ${AppFormatters.currency(remaining.abs())}';
    if (remainingRate < .2) return '⚠️ 今日预算即将用完';
    if (remainingRate < .5) return '今日预算已用 50%，请注意控制';
    return '今日预算充足，继续保持';
  }

  @override
  Widget build(BuildContext context) {
    final recordProvider = context.watch<RecordProvider>();
    final limitProvider = context.watch<LimitProvider>();
    final settings = context.watch<SettingsProvider>();
    final quickActions = settings.quickLedgerCategories
        .map((item) => (item, _iconForCategory(item)))
        .toList();
    final dailyCategories = limitProvider.dailyTrackedCategories;
    final spent =
        recordProvider.spentForCategoriesOnDate(dailyCategories, _selectedDate);
    final limit = limitProvider.config.dailyLimit;
    final remaining = limit - spent;
    final remainingRate = limit == 0 ? 0.0 : remaining / limit;
    final barColor = _statusColor(remainingRate);
    final allRecent = recordProvider.records
        .where((e) => _isSameDay(e.time, _selectedDate))
        .toList();
    final visibleRecentCount = _visibleRecentCount.clamp(0, allRecent.length);
    final recent = allRecent.take(visibleRecentCount).toList();
    final categories = limitProvider.config.categoryLimits.entries.toList()
      ..sort(_sortCategoryEntries);
    final monthlyLimit = limitProvider.config.monthlyLimit;
    final monthlySpent = recordProvider.records
        .where((e) =>
            e.time.year == _selectedDate.year &&
            e.time.month == _selectedDate.month)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final monthlyRemaining = monthlyLimit - monthlySpent;
    final monthlyRemainingRate =
        monthlyLimit == 0 ? 0.0 : monthlyRemaining / monthlyLimit;
    final monthlyBarColor = _statusColor(monthlyRemainingRate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('首页'),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const LimitsScreen())),
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => _changeDate(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        AppFormatters.date(_selectedDate),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _changeDate(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [barColor.withValues(alpha: .16), Colors.white],
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
                      style:
                          Theme.of(context).textTheme.headlineLarge?.copyWith(
                                color: remaining < 0
                                    ? AppColors.danger
                                    : AppColors.text,
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
                    Text(
                        '今日限额：${AppFormatters.currency(limit)} · 已消费：${AppFormatters.currency(spent)}'),
                    const SizedBox(height: 12),
                    StatusBadge(
                        text: _statusText(remainingRate, remaining),
                        color: barColor),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Text('快捷记账', style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _showQuickActionsEditor(context),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('自定义'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Stack(
                children: [
                  Listener(
                    onPointerSignal: _onQuickActionsPointerSignal,
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(
                        dragDevices: {
                          PointerDeviceKind.touch,
                          PointerDeviceKind.mouse,
                          PointerDeviceKind.trackpad,
                          PointerDeviceKind.stylus,
                        },
                      ),
                      child: SizedBox(
                        height: 62,
                        child: ListView.separated(
                          controller: _quickActionsScrollController,
                          scrollDirection: Axis.horizontal,
                          itemCount: quickActions.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 6),
                          itemBuilder: (context, index) {
                            final entry = quickActions[index];
                            return InkWell(
                              onTap: () => _quickAddRecord(context, entry.$1),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 96,
                                height: 62,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.black12),
                                  color: Colors.white,
                                ),
                                child: Stack(
                                  children: [
                                    Align(
                                      alignment: Alignment.topLeft,
                                      child: Icon(entry.$2, size: 18),
                                    ),
                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: Text(
                                        entry.$1,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                                fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  IgnorePointer(
                    child: SizedBox(
                      height: 62,
                      child: Row(
                        children: [
                          Container(
                            width: 18,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [Color(0xFFF9FAFB), Color(0x00F9FAFB)],
                              ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            width: 18,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [Color(0x00F9FAFB), Color(0xFFF9FAFB)],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: _contentScrollController,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  Text('分类限额使用情况',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Expanded(child: Text('月限额使用情况')),
                              Text(AppFormatters.currency(monthlyLimit)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: monthlyLimit == 0
                                  ? 0
                                  : (monthlySpent / monthlyLimit).clamp(0, 1),
                              minHeight: 10,
                              color: monthlyBarColor,
                              backgroundColor: Colors.black12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '本月已用 ${AppFormatters.currency(monthlySpent)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (categories.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: Text('还没有分类限额，先去设置吧')),
                      ),
                    )
                  else
                    ...categories.map((entry) {
                      final setting = entry.value;
                      final amount = setting.selectedAmount;
                      final isDaily = setting.cycle == LimitCycle.daily;
                      final spentAmount = isDaily
                          ? recordProvider.spentForCategoryOnDate(
                              entry.key, _selectedDate)
                          : recordProvider.spentForCategoryMonth(
                              entry.key, _selectedDate);
                      final ratio = amount == 0 ? 0.0 : (spentAmount / amount);
                      final categoryColor = _statusColor(
                          amount == 0 ? 0 : (amount - spentAmount) / amount);
                      final records = isDaily
                          ? recordProvider.recordsForCategoryOnDate(
                              entry.key, _selectedDate)
                          : recordProvider.recordsForCategoryInMonth(
                              entry.key, _selectedDate);
                      return Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _showCategoryRecordsSheet(
                            context: context,
                            category: entry.key,
                            cycle: setting.cycle,
                            date: _selectedDate,
                            records: records,
                            spent: spentAmount,
                            limit: amount,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text(entry.key)),
                                    Text(
                                        '${isDaily ? '日' : '月'} ${AppFormatters.currency(amount)}'),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: ratio.clamp(0, 1),
                                    minHeight: 10,
                                    color: categoryColor,
                                    backgroundColor: Colors.black12,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      '已用 ${AppFormatters.currency(spentAmount)}',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                    const Spacer(),
                                    Text(
                                      '点击查看',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('最近记录',
                          style: Theme.of(context).textTheme.titleMedium),
                      TextButton(
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => RecordsScreen(
                                      filterDate: _selectedDate,
                                    ))),
                        child: const Text('查看全部'),
                      )
                    ],
                  ),
                  if (recent.isEmpty)
                    const Card(
                        child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: Text('还没有消费记录，记第一笔吧'))))
                  else
                    ...recent.map(
                      (e) => Card(
                        child: ListTile(
                          title: Text(e.category),
                          subtitle: Text(e.note.isEmpty
                              ? AppFormatters.dateTime(e.time)
                              : '${e.note} · ${AppFormatters.dateTime(e.time)}'),
                          trailing: Text(AppFormatters.currency(e.amount)),
                        ),
                      ),
                    ),
                  if (recent.isNotEmpty &&
                      visibleRecentCount >= allRecent.length)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Center(child: Text('已显示全部记录')),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
