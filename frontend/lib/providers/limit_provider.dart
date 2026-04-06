import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/limit_config.dart';
import '../services/api_client.dart';

class LimitProvider extends ChangeNotifier {
  static const _storageKey = 'limit_config';
  LimitConfig _config = LimitConfig(
    dailyLimit: 250,
    monthlyLimit: 7500,
    categoryLimits: {'餐饮': 100, '交通': 50, '购物': 50, '娱乐': 80},
  );

  LimitConfig get config => _config;
  double get categoryTotalLimit =>
      _config.categoryLimits.values.fold(0.0, (sum, item) => sum + item);

  LimitProvider() {
    load();
  }

  Future<void> load() async {
    try {
      final data = await ApiClient.instance.get('/limits');
      final limit = data['limit'] as Map<String, dynamic>;
      final categories = (limit['categories'] as List? ?? const []);
      final categoryMap = <String, double>{};
      for (final item in categories) {
        if (item is Map<String, dynamic>) {
          final name = item['name'];
          final amount = item['amount'];
          if (name is String && amount is num) {
            categoryMap[name] = amount.toDouble();
          }
        }
      }

      _config = LimitConfig(
        dailyLimit: (limit['dailyLimit'] as num?)?.toDouble() ?? 250,
        monthlyLimit: (limit['monthlyLimit'] as num?)?.toDouble() ?? 7500,
        categoryLimits: categoryMap,
      );
      if (categoryMap.isNotEmpty) {
        _recomputeTotalFromCategories();
      }
      await _saveLocalCache();
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) _config = LimitConfig.fromJson(jsonDecode(raw));
    }
    notifyListeners();
  }

  Future<void> updateDailyLimit(double value) async {
    _config.dailyLimit = value;
    _config.monthlyLimit = value * 30;
    await _saveRemote();
    await _saveLocalCache();
    notifyListeners();
  }

  Future<void> updateCategoryLimit(String category, double value) async {
    _config.categoryLimits[category] = value;
    _recomputeTotalFromCategories();
    await _saveRemote();
    await _saveLocalCache();
    notifyListeners();
  }

  Future<void> removeCategoryLimit(String category) async {
    _config.categoryLimits.remove(category);
    _recomputeTotalFromCategories();
    await _saveRemote();
    await _saveLocalCache();
    notifyListeners();
  }

  Future<void> syncTotalLimitFromCategories() async {
    _recomputeTotalFromCategories();
    await _saveRemote();
    await _saveLocalCache();
    notifyListeners();
  }

  void _recomputeTotalFromCategories() {
    if (_config.categoryLimits.isEmpty) {
      return;
    }
    _config.dailyLimit = categoryTotalLimit;
    _config.monthlyLimit = _config.dailyLimit * 30;
  }

  Future<void> _saveRemote() async {
    final categories = _config.categoryLimits.entries
        .map((e) => {'name': e.key, 'amount': e.value})
        .toList();
    await ApiClient.instance.put('/limits', {
      'dailyLimit': _config.dailyLimit,
      'categories': categories,
    });
  }

  Future<void> _saveLocalCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_config.toJson()));
  }
}
