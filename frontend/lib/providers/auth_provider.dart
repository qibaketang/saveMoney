import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

class AuthProvider extends ChangeNotifier {
  static const _loginKey = 'logged_in';
  static const _profileKey = 'profile';

  bool _ready = false;
  bool _loggedIn = false;
  UserProfile _profile = const UserProfile(nickname: '预算玩家', phone: '13800000000');

  bool get ready => _ready;
  bool get loggedIn => _loggedIn;
  UserProfile get profile => _profile;

  AuthProvider() {
    load();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _loggedIn = prefs.getBool(_loginKey) ?? false;
    final raw = prefs.getString(_profileKey);
    if (raw != null) {
      _profile = UserProfile.fromJson(jsonDecode(raw));
    }
    _ready = true;
    notifyListeners();
  }

  Future<void> login(String phone) async {
    _loggedIn = true;
    _profile = UserProfile(nickname: '用户${phone.substring(phone.length - 4)}', phone: phone);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loginKey, true);
    await prefs.setString(_profileKey, jsonEncode(_profile.toJson()));
    notifyListeners();
  }

  Future<void> logout() async {
    _loggedIn = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loginKey, false);
    notifyListeners();
  }
}
