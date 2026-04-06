import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/formatters.dart';
import '../../models/expense_record.dart';
import '../../services/api_client.dart';
import '../../providers/record_provider.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  Future<void> _showEditDialog(
      BuildContext context, ExpenseRecord record) async {
    final amountController =
        TextEditingController(text: record.amount.toStringAsFixed(2));
    final categoryController = TextEditingController(text: record.category);
    final noteController = TextEditingController(text: record.note);
    DateTime selectedDate = record.time;

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('编辑记录'),
          content: SingleChildScrollView(
            child: Column(
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
                  controller: categoryController,
                  decoration: const InputDecoration(labelText: '分类'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(labelText: '备注'),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_month_outlined),
                  title: const Text('消费日期'),
                  subtitle: Text(AppFormatters.date(selectedDate)),
                  trailing: TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020, 1, 1),
                        lastDate: DateTime(2100, 12, 31),
                      );
                      if (picked == null) {
                        return;
                      }
                      setDialogState(() {
                        selectedDate = DateTime(
                          picked.year,
                          picked.month,
                          picked.day,
                          selectedDate.hour,
                          selectedDate.minute,
                        );
                      });
                    },
                    child: const Text('选择日期'),
                  ),
                ),
              ],
            ),
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
      ),
    );

    if (shouldSave != true || !context.mounted) {
      return;
    }

    final amount = double.tryParse(amountController.text.trim());
    final category = categoryController.text.trim();
    if (amount == null || amount <= 0 || category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写合法的金额和分类')),
      );
      return;
    }

    try {
      await context.read<RecordProvider>().updateRecord(
            id: record.id,
            category: category,
            amount: amount,
            note: noteController.text.trim(),
            tags: record.tags,
            time: selectedDate,
            location: record.location,
          );
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('更新成功')),
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      final message = e is ApiException ? e.message : '更新失败，请稍后重试';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final records = context.watch<RecordProvider>().records;
    return Scaffold(
      appBar: AppBar(title: const Text('消费记录')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: records.length,
        itemBuilder: (context, index) {
          final record = records[index];
          return Dismissible(
            key: ValueKey(record.id),
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.delete_outline),
            ),
            onDismissed: (_) =>
                context.read<RecordProvider>().deleteRecord(record.id),
            child: Card(
              child: ListTile(
                title: Text(record.category),
                subtitle: Text(
                    '${record.note.isEmpty ? '无备注' : record.note} · ${AppFormatters.dateTime(record.time)}'),
                onTap: () => _showEditDialog(context, record),
                leading: IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _showEditDialog(context, record),
                ),
                trailing: Text(AppFormatters.currency(record.amount)),
              ),
            ),
          );
        },
      ),
    );
  }
}
