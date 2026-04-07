import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/formatters.dart';
import '../../providers/record_provider.dart';

class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  final amountController = TextEditingController();
  final noteController = TextEditingController();
  final categories = ['餐饮', '交通', '购物', '娱乐', '医疗', '学习', '居住', '其他'];
  String selectedCategory = '餐饮';
  final selectedTags = <String>{};
  final tags = ['外卖', '公司', '周末', '通勤', '冲动消费'];
  DateTime selectedDate = DateTime.now();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('zh', 'CN'),
      initialDate: selectedDate,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2100, 12, 31),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      selectedDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
        selectedDate.hour,
        selectedDate.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('记一笔')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: Theme.of(context).textTheme.headlineMedium,
            decoration:
                const InputDecoration(labelText: '金额', hintText: '¥ 0.00'),
          ),
          const SizedBox(height: 16),
          Text('选择分类', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories
                .map(
                  (category) => ChoiceChip(
                    label: Text(category),
                    selected: selectedCategory == category,
                    onSelected: (_) =>
                        setState(() => selectedCategory = category),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          TextField(
              controller: noteController,
              decoration: const InputDecoration(
                  labelText: '备注', hintText: '午餐 / 充值 / 周末采购')),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_month_outlined),
              title: const Text('消费日期'),
              subtitle: Text(AppFormatters.date(selectedDate)),
              trailing: TextButton(
                onPressed: _pickDate,
                child: const Text('选择日期'),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags
                .map((tag) => FilterChip(
                    label: Text(tag),
                    selected: selectedTags.contains(tag),
                    onSelected: (_) {
                      setState(() {
                        selectedTags.contains(tag)
                            ? selectedTags.remove(tag)
                            : selectedTags.add(tag);
                      });
                    }))
                .toList(),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) return;
              await context.read<RecordProvider>().addRecord(
                    category: selectedCategory,
                    amount: amount,
                    note: noteController.text,
                    tags: selectedTags.toList(),
                    time: selectedDate,
                  );
              if (!mounted) return;
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('保存成功')));
              amountController.clear();
              noteController.clear();
              setState(() {
                selectedTags.clear();
                selectedDate = DateTime.now();
              });
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('保存记账'),
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('下一步可扩展：拍照上传消费凭证、定位、语音记账、OCR 小票识别。'),
            ),
          )
        ],
      ),
    );
  }
}
