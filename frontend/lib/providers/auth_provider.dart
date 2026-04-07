import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../services/api_client.dart';

class AuthProvider extends ChangeNotifier {
  static const _loginKey = 'logged_in';
  static const _profileKey = 'profile';
  static const _tokenKey = 'auth_token';

  bool _ready = false;
  bool _loggedIn = false;
  UserProfile _profile =
      const UserProfile(nickname: '预算玩家', phone: '13800000000');
  String _token = '';

  bool get ready => _ready;
  bool get loggedIn => _loggedIn;
  UserProfile get profile => _profile;
  String get token => _token;
  String get cacheScope {
    if (!_loggedIn) {
      return 'guest';
    }
    final phone = _profile.phone.trim();
    return phone.isEmpty ? 'guest' : phone;
  }

  AuthProvider() {
    ApiClient.instance.setUnauthorizedHandler(_handleUnauthorized);
    load();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _loggedIn = prefs.getBool(_loginKey) ?? false;
    final raw = prefs.getString(_profileKey);
    _token = prefs.getString(_tokenKey) ?? '';
    if (raw != null) {
      _profile = UserProfile.fromJson(jsonDecode(raw));
    }
    _ready = true;
    notifyListeners();
  }

  Future<void> login(String phone) async {
    final data = await ApiClient.instance
        .post('/auth/login', {'phone': phone}, withAuth: false);
    await _saveAuthResult(data);
  }

  Future<void> loginWithPassword(String phone, String password) async {
    final data = await ApiClient.instance.post(
      '/auth/login/password',
      {'phone': phone, 'password': password},
      withAuth: false,
    );
    await _saveAuthResult(data);
  }

  Future<void> registerWithCode({
    required String phone,
    required String verifyCode,
    required String password,
    String? nickname,
  }) async {
    final payload = <String, dynamic>{
      'phone': phone,
      'verifyCode': verifyCode,
      'password': password,
    };
    if (nickname != null && nickname.trim().isNotEmpty) {
      payload['nickname'] = nickname.trim();
    }
    final data = await ApiClient.instance.post(
      '/auth/register',
      payload,
      withAuth: false,
    );
    await _saveAuthResult(data);
  }

  Future<String> requestVerifyCode(String phone) async {
    final data = await ApiClient.instance.post(
      '/auth/send-code',
      {'phone': phone},
      withAuth: false,
    );
    return (data['mockCode'] ?? '').toString();
  }

  Future<void> _saveAuthResult(Map<String, dynamic> data) async {
    _token = (data['accessToken'] ?? '').toString();
    _profile = UserProfile.fromApi(data['user'] as Map<String, dynamic>);
    _loggedIn = _token.isNotEmpty;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loginKey, _loggedIn);
    await prefs.setString(_profileKey, jsonEncode(_profile.toJson()));
    await prefs.setString(_tokenKey, _token);
    notifyListeners();
  }

  Future<void> logout() async {
    _loggedIn = false;
    _token = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loginKey, false);
    await prefs.remove(_profileKey);
    await prefs.remove(_tokenKey);
    notifyListeners();
  }

  Future<void> _handleUnauthorized() async {
    if (!_loggedIn && _token.isEmpty) {
      return;
    }

    _loggedIn = false;
    _token = '';
    _profile = const UserProfile(nickname: '预算玩家', phone: '13800000000');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loginKey, false);
    await prefs.remove(_profileKey);
    await prefs.remove(_tokenKey);

    notifyListeners();
  }
}
