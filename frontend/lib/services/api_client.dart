import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/api_contract.dart';

class ApiException implements Exception {
  final String code;
  final String message;
  final int statusCode;

  const ApiException(this.code, this.message, {this.statusCode = 500});

  @override
  String toString() =>
      'ApiException(status: $statusCode, code: $code, message: $message)';
}

class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  static const String _baseUrl = 'http://localhost:3000/api';
  static const String _tokenKey = 'auth_token';

  Future<void> Function()? _onUnauthorized;

  void setUnauthorizedHandler(Future<void> Function()? handler) {
    _onUnauthorized = handler;
  }

  Future<Map<String, String>> _headers({bool withAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (withAuth) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<Map<String, dynamic>> get(String path, {bool withAuth = true}) async {
    final response = await http.get(
      Uri.parse('$_baseUrl$path'),
      headers: await _headers(withAuth: withAuth),
    );
    return _parseEnvelope(response);
  }

  Future<Map<String, dynamic>> post(String path, Object body,
      {bool withAuth = true}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$path'),
      headers: await _headers(withAuth: withAuth),
      body: jsonEncode(body),
    );
    return _parseEnvelope(response);
  }

  Future<Map<String, dynamic>> put(String path, Object body,
      {bool withAuth = true}) async {
    final response = await http.put(
      Uri.parse('$_baseUrl$path'),
      headers: await _headers(withAuth: withAuth),
      body: jsonEncode(body),
    );
    return _parseEnvelope(response);
  }

  Future<Map<String, dynamic>> delete(String path,
      {bool withAuth = true}) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl$path'),
      headers: await _headers(withAuth: withAuth),
    );
    return _parseEnvelope(response);
  }

  Map<String, dynamic> _parseEnvelope(http.Response response) {
    Map<String, dynamic> jsonBody = <String, dynamic>{};
    if (response.body.isNotEmpty) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        jsonBody = decoded;
      }
    }

    final rawCode = jsonBody[ApiEnvelopeKeys.code];
    final code = _resolveErrorCode(response.statusCode, rawCode);
    final message = (jsonBody[ApiEnvelopeKeys.message] ?? '').toString();

    final isSuccess =
        response.statusCode >= 200 && response.statusCode < 300 && rawCode == 0;
    if (!isSuccess) {
      if (_isUnauthorized(code)) {
        _onUnauthorized?.call();
      }

      throw ApiException(
        code,
        _mapMessage(code, message),
        statusCode: response.statusCode,
      );
    }

    final data = jsonBody[ApiEnvelopeKeys.data];
    if (data is Map<String, dynamic>) {
      return data;
    }

    return <String, dynamic>{'value': data};
  }

  bool _isUnauthorized(String code) {
    return code == ApiErrorCodes.authMissingToken ||
        code == ApiErrorCodes.authInvalidToken;
  }

  String _resolveErrorCode(int statusCode, dynamic rawCode) {
    if (rawCode is String && rawCode.isNotEmpty) {
      return rawCode;
    }

    if (statusCode == 401 || statusCode == 403) {
      return ApiErrorCodes.authInvalidToken;
    }
    if (statusCode == 404) {
      return ApiErrorCodes.resourceNotFound;
    }
    if (statusCode == 400) {
      return ApiErrorCodes.validationFailed;
    }
    return ApiErrorCodes.internalServerError;
  }

  String _mapMessage(String code, String serverMessage) {
    if (serverMessage.isNotEmpty && serverMessage != '请求失败') {
      return serverMessage;
    }

    switch (code) {
      case ApiErrorCodes.authMissingToken:
      case ApiErrorCodes.authInvalidToken:
        return '登录状态已失效，请重新登录';
      case ApiErrorCodes.authInvalidPhone:
        return '手机号格式不正确';
      case ApiErrorCodes.authInvalidPassword:
        return '密码不符合要求，请输入 6-32 位';
      case ApiErrorCodes.authInvalidVerifyCode:
        return '验证码错误，请使用演示验证码 123456';
      case ApiErrorCodes.authPhoneExists:
        return '该手机号已注册，请直接登录';
      case ApiErrorCodes.authUserNotFound:
        return '账号不存在，请先注册';
      case ApiErrorCodes.authWrongPassword:
        return '手机号或密码错误';
      case ApiErrorCodes.validationFailed:
        return '请求参数不合法，请检查后重试';
      case ApiErrorCodes.resourceNotFound:
        return '请求资源不存在';
      default:
        return '服务器开小差了，请稍后重试';
    }
  }
}
