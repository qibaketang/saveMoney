enum LimitCycle { daily, monthly }

class CategoryLimitSetting {
  LimitCycle cycle;
  double dailyLimit;
  double monthlyLimit;

  CategoryLimitSetting({
    required this.cycle,
    required this.dailyLimit,
    required this.monthlyLimit,
  });

  factory CategoryLimitSetting.daily(double value) => CategoryLimitSetting(
        cycle: LimitCycle.daily,
        dailyLimit: value,
        monthlyLimit: 0,
      );

  factory CategoryLimitSetting.monthly(double value) => CategoryLimitSetting(
        cycle: LimitCycle.monthly,
        dailyLimit: 0,
        monthlyLimit: value,
      );

  factory CategoryLimitSetting.fromJson(dynamic raw) {
    if (raw is num) {
      return CategoryLimitSetting.daily(raw.toDouble());
    }
    if (raw is! Map<String, dynamic>) {
      return CategoryLimitSetting.daily(0);
    }

    final cycleRaw = (raw['cycle'] ?? raw['mode'] ?? 'daily').toString();
    final cycle = cycleRaw == 'monthly' ? LimitCycle.monthly : LimitCycle.daily;
    final dailyLimit = (raw['dailyLimit'] as num?)?.toDouble() ??
        ((cycle == LimitCycle.daily ? raw['amount'] : 0) as num?)?.toDouble() ??
        0;
    final monthlyLimit = (raw['monthlyLimit'] as num?)?.toDouble() ??
        ((cycle == LimitCycle.monthly ? raw['amount'] : 0) as num?)?.toDouble() ??
        0;

    return CategoryLimitSetting(
      cycle: cycle,
      dailyLimit: dailyLimit,
      monthlyLimit: monthlyLimit,
    );
  }

  CategoryLimitSetting copy() => CategoryLimitSetting(
        cycle: cycle,
        dailyLimit: dailyLimit,
        monthlyLimit: monthlyLimit,
      );

  double get selectedAmount => cycle == LimitCycle.daily ? dailyLimit : monthlyLimit;

  Map<String, dynamic> toJson() => {
        'cycle': cycle == LimitCycle.daily ? 'daily' : 'monthly',
        'dailyLimit': dailyLimit,
        'monthlyLimit': monthlyLimit,
      };
}

class LimitConfig {
  double dailyLimit;
  double monthlyLimit;
  Map<String, CategoryLimitSetting> categoryLimits;

  LimitConfig({
    required this.dailyLimit,
    required this.monthlyLimit,
    required this.categoryLimits,
  });

  LimitConfig copy() => LimitConfig(
        dailyLimit: dailyLimit,
        monthlyLimit: monthlyLimit,
        categoryLimits: categoryLimits.map((key, value) => MapEntry(key, value.copy())),
      );

  factory LimitConfig.fromJson(Map<String, dynamic> json) => LimitConfig(
        dailyLimit: (json['dailyLimit'] as num?)?.toDouble() ?? 250,
        monthlyLimit: (json['monthlyLimit'] as num?)?.toDouble() ?? 8000,
        categoryLimits: (json['categoryLimits'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, CategoryLimitSetting.fromJson(value)),
        ),
      );

  Map<String, dynamic> toJson() => {
        'dailyLimit': dailyLimit,
        'monthlyLimit': monthlyLimit,
        'categoryLimits': categoryLimits,
      };
}
