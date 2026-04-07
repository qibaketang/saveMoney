import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/limit_config.dart';
import '../services/api_client.dart';

class LimitProvider extends ChangeNotifier {
  static const _storageKeyBase = 'limit_config';
  String _scope = 'guest';
  LimitConfig _config = _defaultConfig();

  static LimitConfig _defaultConfig() => LimitConfig(
        dailyLimit: 250,
        monthlyLimit: 8000,
        categoryLimits: {
          '餐饮': CategoryLimitSetting.daily(100),
          '交通': CategoryLimitSetting.daily(50),
          '购物': CategoryLimitSetting.daily(50),
          '娱乐': CategoryLimitSetting.daily(80),
        },
      );

  String get _storageKey => '$_storageKeyBase::$_scope';
  static const String dailyBudgetCategory = '餐饮';

  LimitConfig get config => _config;
  DateTime get currentMonth => DateTime(DateTime.now().year, DateTime.now().month, 1);

  Set<String> get dailyTrackedCategories => {dailyBudgetCategory};

  double computeMonthlyTotal({
    required double dailyLimit,
    required double monthlyCategoryLimit,
    required DateTime month,
  }) {
    final days = DateUtils.getDaysInMonth(month.year, month.month);
    return (dailyLimit * days) + monthlyCategoryLimit;
  }

  int daysOfMonth(DateTime month) => DateUtils.getDaysInMonth(month.year, month.month);

  LimitConfig normalizeConfig(LimitConfig source, {DateTime? month}) {
    final normalized = source.copy();
    final targetMonth = month ?? currentMonth;
    final foodLimit = normalized.categoryLimits[dailyBudgetCategory];
    if (foodLimit != null && foodLimit.cycle == LimitCycle.daily) {
      normalized.dailyLimit = foodLimit.dailyLimit;
    }

    final monthlyCategorySum = normalized.categoryLimits.values
        .where((setting) => setting.cycle == LimitCycle.monthly)
        .fold<double>(0, (sum, item) => sum + item.monthlyLimit);
    normalized.monthlyLimit = computeMonthlyTotal(
      dailyLimit: normalized.dailyLimit,
      monthlyCategoryLimit: monthlyCategorySum,
      month: targetMonth,
    );
    return normalized;
  }

  LimitProvider() {
    load();
  }

  void applyAuthContext({required String scope, required bool loggedIn}) {
    final normalizedScope = loggedIn ? scope : 'guest';
    if (_scope == normalizedScope) {
      return;
    }
    _scope = normalizedScope;
    if (!loggedIn) {
      _config = _defaultConfig();
      notifyListeners();
      return;
    }
    load();
  }

  Future<void> load() async {
    try {
      final data = await ApiClient.instance.get('/limits');
      final limit = data['limit'] as Map<String, dynamic>;
      final categories = (limit['categories'] as List? ?? const []);
      final categoryMap = <String, CategoryLimitSetting>{};
      for (final item in categories) {
        if (item is Map<String, dynamic>) {
          final name = item['name'];
          if (name is String) {
            categoryMap[name] = CategoryLimitSetting.fromJson(item);
          }
        }
      }

      _config = LimitConfig(
        dailyLimit: (limit['dailyLimit'] as num?)?.toDouble() ?? 250,
        monthlyLimit: (limit['monthlyLimit'] as num?)?.toDouble() ?? 8000,
        categoryLimits: categoryMap,
      );
      _config = normalizeConfig(_config);
      await _saveLocalCache();
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) _config = LimitConfig.fromJson(jsonDecode(raw));
    }
    notifyListeners();
  }

  Future<void> saveConfig(LimitConfig next) async {
    _config = normalizeConfig(next);
    await _saveRemote();
    await _saveLocalCache();
    notifyListeners();
  }

  Future<void> _saveRemote() async {
    final categories = _config.categoryLimits.entries
        .map((e) => {
              'name': e.key,
              'cycle': e.value.cycle == LimitCycle.daily ? 'daily' : 'monthly',
              'dailyLimit': e.value.dailyLimit,
              'monthlyLimit': e.value.monthlyLimit,
              'amount': e.value.selectedAmount,
            })
        .toList();
    await ApiClient.instance.put('/limits', {
      'dailyLimit': _config.dailyLimit,
      'monthlyLimit': _config.monthlyLimit,
      'categories': categories,
    });
  }

  Future<void> _saveLocalCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_config.toJson()));
  }
}
