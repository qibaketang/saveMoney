import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saving_goal.dart';
import '../services/api_client.dart';

class GoalProvider extends ChangeNotifier {
  static const _storageKey = 'saving_goal';
  SavingGoal? _goal;
  SavingGoal? get goal => _goal;

  GoalProvider() {
    load();
  }

  Future<void> load() async {
    try {
      final data = await ApiClient.instance.get('/goals');
      _goal = SavingGoal.fromApi(data['goal'] as Map<String, dynamic>);
      await _saveLocalCache(_goal!);
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        _goal = SavingGoal.fromJson(jsonDecode(raw));
      }
    }
    notifyListeners();
  }

  Future<void> saveGoal(SavingGoal goal) async {
    _goal = goal;
    await ApiClient.instance.put('/goals', goal.toApiJson());
    await _saveLocalCache(goal);
    notifyListeners();
  }

  Future<void> _saveLocalCache(SavingGoal goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(goal.toJson()));
  }
}
