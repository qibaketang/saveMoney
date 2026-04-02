import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/limit_config.dart';

class LimitProvider extends ChangeNotifier {
  static const _storageKey = 'limit_config';
  LimitConfig _config = LimitConfig(
    dailyLimit: 250,
    monthlyLimit: 7500,
    categoryLimits: {'餐饮': 100, '交通': 50, '购物': 50, '娱乐': 80},
  );

  LimitConfig get config => _config;

  LimitProvider() {
    load();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null) _config = LimitConfig.fromJson(jsonDecode(raw));
    notifyListeners();
  }

  Future<void> updateDailyLimit(double value) async {
    _config.dailyLimit = value;
    _config.monthlyLimit = value * 30;
    await _save();
  }

  Future<void> updateCategoryLimit(String category, double value) async {
    _config.categoryLimits[category] = value;
    await _save();
  }

  Future<void> removeCategoryLimit(String category) async {
    _config.categoryLimits.remove(category);
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_config.toJson()));
    notifyListeners();
  }
}
