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

  double get progress => targetAmount == 0 ? 0 : (currentAmount / targetAmount).clamp(0, 1);
  double get remaining => targetAmount - currentAmount;

  factory SavingGoal.fromJson(Map<String, dynamic> json) => SavingGoal(
        title: json['title'] as String,
        targetAmount: (json['targetAmount'] as num).toDouble(),
        currentAmount: (json['currentAmount'] as num).toDouble(),
        deadline: DateTime.parse(json['deadline'] as String),
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        'deadline': deadline.toIso8601String(),
      };
}
