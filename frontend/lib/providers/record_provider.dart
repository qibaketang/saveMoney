import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/expense_record.dart';

class RecordProvider extends ChangeNotifier {
  static const _storageKey = 'records';
  final _uuid = const Uuid();
  List<ExpenseRecord> _records = [];
  List<ExpenseRecord> get records => List.unmodifiable(_records);

  RecordProvider() {
    load();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? [];
    _records = raw.map((e) => ExpenseRecord.fromJson(jsonDecode(e))).toList();
    if (_records.isEmpty) {
      _records = [
        ExpenseRecord(id: _uuid.v4(), category: '早餐', amount: 12, note: '豆浆油条', tags: const ['工作日'], time: DateTime.now().subtract(const Duration(hours: 1))),
        ExpenseRecord(id: _uuid.v4(), category: '交通', amount: 5, note: '地铁', tags: const ['通勤'], time: DateTime.now().subtract(const Duration(hours: 3))),
        ExpenseRecord(id: _uuid.v4(), category: '咖啡', amount: 28, note: '拿铁', tags: const ['提神'], time: DateTime.now().subtract(const Duration(hours: 5))),
        ExpenseRecord(id: _uuid.v4(), category: '购物', amount: 76, note: '日用品', tags: const ['周末'], time: DateTime.now().subtract(const Duration(days: 1))),
      ];
      await _save();
      return;
    }
    notifyListeners();
  }

  Future<void> addRecord({
    required String category,
    required double amount,
    String note = '',
    List<String> tags = const [],
    DateTime? time,
    String? location,
  }) async {
    final record = ExpenseRecord(
      id: _uuid.v4(),
      category: category,
      amount: amount,
      note: note,
      tags: tags,
      time: time ?? DateTime.now(),
      location: location,
    );
    _records.insert(0, record);
    await _save();
  }

  Future<void> deleteRecord(String id) async {
    _records.removeWhere((e) => e.id == id);
    await _save();
  }

  double get todaySpent {
    final now = DateTime.now();
    return _records
        .where((e) => e.time.year == now.year && e.time.month == now.month && e.time.day == now.day)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  int get todayCount {
    final now = DateTime.now();
    return _records.where((e) => e.time.year == now.year && e.time.month == now.month && e.time.day == now.day).length;
  }

  double spentForCategoryToday(String category) {
    final now = DateTime.now();
    return _records
        .where((e) => e.category == category && e.time.year == now.year && e.time.month == now.month && e.time.day == now.day)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  Map<String, double> categorySpendForMonth(DateTime date) {
    final map = <String, double>{};
    for (final record in _records.where((e) => e.time.year == date.year && e.time.month == date.month)) {
      map.update(record.category, (v) => v + record.amount, ifAbsent: () => record.amount);
    }
    return map;
  }

  List<double> dailySpendForMonth(DateTime date) {
    final days = DateUtils.getDaysInMonth(date.year, date.month);
    final result = List<double>.filled(days, 0);
    for (final record in _records.where((e) => e.time.year == date.year && e.time.month == date.month)) {
      result[record.time.day - 1] += record.amount;
    }
    return result;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, _records.map((e) => jsonEncode(e.toJson())).toList());
    notifyListeners();
  }
}
