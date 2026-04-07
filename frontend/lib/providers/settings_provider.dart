import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const _storageKeyBase = 'settings';
  String _scope = 'guest';

  bool limitAlert = true;
  bool overLimitAlert = true;
  bool pushNotification = true;
  bool smsNotification = false;
  bool darkMode = false;
  bool quickLedger = true;

  String get _storageKey => '$_storageKeyBase::$_scope';

  SettingsProvider() {
    load();
  }

  void applyAuthContext({required String scope, required bool loggedIn}) {
    final normalizedScope = loggedIn ? scope : 'guest';
    if (_scope == normalizedScope) {
      return;
    }
    _scope = normalizedScope;
    if (!loggedIn) {
      limitAlert = true;
      overLimitAlert = true;
      pushNotification = true;
      smsNotification = false;
      darkMode = false;
      quickLedger = true;
      notifyListeners();
      return;
    }
    load();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    limitAlert = json['limitAlert'] ?? true;
    overLimitAlert = json['overLimitAlert'] ?? true;
    pushNotification = json['pushNotification'] ?? true;
    smsNotification = json['smsNotification'] ?? false;
    darkMode = json['darkMode'] ?? false;
    quickLedger = json['quickLedger'] ?? true;
    notifyListeners();
  }

  Future<void> update({
    bool? limitAlertValue,
    bool? overLimitAlertValue,
    bool? pushNotificationValue,
    bool? smsNotificationValue,
    bool? darkModeValue,
    bool? quickLedgerValue,
  }) async {
    limitAlert = limitAlertValue ?? limitAlert;
    overLimitAlert = overLimitAlertValue ?? overLimitAlert;
    pushNotification = pushNotificationValue ?? pushNotification;
    smsNotification = smsNotificationValue ?? smsNotification;
    darkMode = darkModeValue ?? darkMode;
    quickLedger = quickLedgerValue ?? quickLedger;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode({
      'limitAlert': limitAlert,
      'overLimitAlert': overLimitAlert,
      'pushNotification': pushNotification,
      'smsNotification': smsNotification,
      'darkMode': darkMode,
      'quickLedger': quickLedger,
    }));
    notifyListeners();
  }
}
