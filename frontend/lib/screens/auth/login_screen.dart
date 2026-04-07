import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';

enum AuthMode { quick, password, register }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController(text: '13800138000');
  final _passwordController = TextEditingController(text: '123456');
  final _codeController = TextEditingController(text: '123456');
  final _nicknameController = TextEditingController();

  AuthMode _mode = AuthMode.password;
  bool _submitting = false;
  bool _obscurePassword = true;
  int _countdown = 0;
  Timer? _countdownTimer;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _phoneController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _requestVerifyCode() async {
    if (_countdown > 0) {
      return;
    }
    final phone = _phoneController.text.trim();
    if (!RegExp(r'^1\d{10}$').hasMatch(phone)) {
      _showMessage('请先输入正确手机号');
      return;
    }

    try {
      final mockCode = await context.read<AuthProvider>().requestVerifyCode(phone);
      _showMessage(mockCode.isEmpty ? '验证码已发送，请注意查收' : '验证码已发送，演示码：$mockCode');
      _startCountdown();
    } catch (e) {
      final message = e is ApiException ? e.message : '发送失败，请稍后再试';
      _showMessage(message);
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _countdown = 60);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _countdown <= 1) {
        timer.cancel();
        if (mounted) {
          setState(() => _countdown = 0);
        }
        return;
      }
      setState(() => _countdown -= 1);
    });
  }

  Future<void> _submit() async {
    if (_submitting) {
      return;
    }
    final phone = _phoneController.text.trim();
    if (!RegExp(r'^1\d{10}$').hasMatch(phone)) {
      _showMessage('请输入 11 位手机号');
      return;
    }

    setState(() => _submitting = true);
    try {
      final auth = context.read<AuthProvider>();
      if (_mode == AuthMode.quick) {
        await auth.login(phone);
      } else if (_mode == AuthMode.password) {
        final password = _passwordController.text;
        if (password.length < 6) {
          _showMessage('密码至少 6 位');
          return;
        }
        await auth.loginWithPassword(phone, password);
      } else {
        final password = _passwordController.text;
        final code = _codeController.text.trim();
        if (password.length < 6) {
          _showMessage('密码至少 6 位');
          return;
        }
        if (code.length < 4) {
          _showMessage('请输入验证码');
          return;
        }
        await auth.registerWithCode(
          phone: phone,
          verifyCode: code,
          password: password,
          nickname: _nicknameController.text,
        );
      }
    } catch (e) {
      final message = e is ApiException ? e.message : '操作失败，请稍后重试';
      _showMessage(message);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String get _primaryActionText {
    switch (_mode) {
      case AuthMode.quick:
        return '验证码快捷登录';
      case AuthMode.password:
        return '手机号密码登录';
      case AuthMode.register:
        return '手机号验证码注册';
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            children: [
              const SizedBox(height: 48),
              Text(
                'Budget Guard',
                style: textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                '限额驱动型记账存钱 App\n3 秒记账，实时预算预警。',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SegmentedButton<AuthMode>(
                        segments: const [
                          ButtonSegment(
                            value: AuthMode.password,
                            label: Text('密码登录'),
                          ),
                          ButtonSegment(
                            value: AuthMode.register,
                            label: Text('验证码注册'),
                          ),
                          ButtonSegment(
                            value: AuthMode.quick,
                            label: Text('快捷登录'),
                          ),
                        ],
                        selected: {_mode},
                        onSelectionChanged: (selection) {
                          setState(() => _mode = selection.first);
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: '手机号'),
                      ),
                      if (_mode == AuthMode.register) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _nicknameController,
                          decoration: const InputDecoration(
                            labelText: '昵称（可选）',
                          ),
                        ),
                      ],
                      if (_mode == AuthMode.password ||
                          _mode == AuthMode.register) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: '密码',
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() => _obscurePassword = !_obscurePassword);
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (_mode == AuthMode.register) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _codeController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: '验证码（演示）',
                                  hintText: '默认 123456',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            FilledButton.tonal(
                              onPressed: _countdown > 0 || _submitting
                                  ? null
                                  : _requestVerifyCode,
                              child: Text(
                                _countdown > 0 ? '${_countdown}s' : '获取验证码',
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            '短信能力待接入，当前返回演示验证码用于联调。',
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _submitting ? null : _submit,
                        child: SizedBox(
                          width: double.infinity,
                          child: Center(
                            child: Text(_submitting ? '提交中...' : _primaryActionText),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text('短信验证码能力预留，当前可使用默认验证码 123456 进行测试。'),
            ],
          ),
        ),
      ),
    );
  }
}
