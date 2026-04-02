import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/formatters.dart';
import '../../providers/record_provider.dart';

class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key});

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
              decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.delete_outline),
            ),
            onDismissed: (_) => context.read<RecordProvider>().deleteRecord(record.id),
            child: Card(
              child: ListTile(
                title: Text(record.category),
                subtitle: Text('${record.note.isEmpty ? '无备注' : record.note} · ${AppFormatters.dateTime(record.time)}'),
                trailing: Text(AppFormatters.currency(record.amount)),
              ),
            ),
          );
        },
      ),
    );
  }
}
