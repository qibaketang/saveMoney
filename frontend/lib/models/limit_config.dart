class LimitConfig {
  double dailyLimit;
  double monthlyLimit;
  Map<String, double> categoryLimits;

  LimitConfig({
    required this.dailyLimit,
    required this.monthlyLimit,
    required this.categoryLimits,
  });

  factory LimitConfig.fromJson(Map<String, dynamic> json) => LimitConfig(
        dailyLimit: (json['dailyLimit'] as num).toDouble(),
        monthlyLimit: (json['monthlyLimit'] as num).toDouble(),
        categoryLimits: (json['categoryLimits'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        ),
      );

  Map<String, dynamic> toJson() => {
        'dailyLimit': dailyLimit,
        'monthlyLimit': monthlyLimit,
        'categoryLimits': categoryLimits,
      };
}
