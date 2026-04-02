import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saving_goal.dart';

class GoalProvider extends ChangeNotifier {
  static const _storageKey = 'saving_goal';
  SavingGoal? _goal;
  SavingGoal? get goal => _goal;

  GoalProvider() {
    load();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      _goal = SavingGoal.fromJson(jsonDecode(raw));
    } else {
      _goal = SavingGoal(
        title: '旅行基金',
        targetAmount: 6000,
        currentAmount: 1800,
        deadline: DateTime.now().add(const Duration(days: 180)),
      );
      await saveGoal(_goal!);
      return;
    }
    notifyListeners();
  }

  Future<void> saveGoal(SavingGoal goal) async {
    _goal = goal;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(goal.toJson()));
    notifyListeners();
  }
}
