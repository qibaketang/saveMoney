class SavingGoal {
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime deadline;

  const SavingGoal({
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.deadline,
  });

  double get progress =>
      targetAmount == 0 ? 0 : (currentAmount / targetAmount).clamp(0, 1);
  double get remaining => targetAmount - currentAmount;

  factory SavingGoal.fromJson(Map<String, dynamic> json) => SavingGoal(
        title: json['title'] as String,
        targetAmount: (json['targetAmount'] as num).toDouble(),
        currentAmount: (json['currentAmount'] as num).toDouble(),
        deadline: DateTime.parse(json['deadline'] as String),
      );

  factory SavingGoal.fromApi(Map<String, dynamic> json) => SavingGoal(
        title: json['name'] as String? ?? '储蓄目标',
        targetAmount: (json['targetAmount'] as num?)?.toDouble() ?? 0,
        currentAmount: (json['savedAmount'] as num?)?.toDouble() ?? 0,
        deadline: DateTime.tryParse((json['targetDate'] ?? '').toString()) ??
            DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        'deadline': deadline.toIso8601String(),
      };

  Map<String, dynamic> toApiJson() => {
        'name': title,
        'targetAmount': targetAmount,
        'savedAmount': currentAmount,
        'targetDate': deadline.toIso8601String(),
      };
}
