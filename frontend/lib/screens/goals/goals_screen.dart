import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/formatters.dart';
import '../../models/saving_goal.dart';
import '../../providers/goal_provider.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final titleController = TextEditingController();
  final targetController = TextEditingController();
  final currentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final goal = context.watch<GoalProvider>().goal;
    if (goal != null && titleController.text.isEmpty) {
      titleController.text = goal.title;
      targetController.text = goal.targetAmount.toStringAsFixed(0);
      currentController.text = goal.currentAmount.toStringAsFixed(0);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('存钱目标')),
      body: goal == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(goal.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('已存 ${AppFormatters.currency(goal.currentAmount)} / 目标 ${AppFormatters.currency(goal.targetAmount)}'),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(value: goal.progress, minHeight: 12, borderRadius: BorderRadius.circular(8)),
                        const SizedBox(height: 12),
                        Text('还需 ${AppFormatters.currency(goal.remaining)} · 截止 ${AppFormatters.date(goal.deadline)}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(controller: titleController, decoration: const InputDecoration(labelText: '目标名称')),
                const SizedBox(height: 12),
                TextField(controller: targetController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '目标金额')),
                const SizedBox(height: 12),
                TextField(controller: currentController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '当前金额')),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    final target = double.tryParse(targetController.text) ?? 0;
                    final current = double.tryParse(currentController.text) ?? 0;
                    await context.read<GoalProvider>().saveGoal(
                          SavingGoal(
                            title: titleController.text,
                            targetAmount: target,
                            currentAmount: current,
                            deadline: DateTime.now().add(const Duration(days: 180)),
                          ),
                        );
                  },
                  child: const Text('保存目标'),
                )
              ],
            ),
    );
  }
}
