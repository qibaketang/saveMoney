import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final controller = TextEditingController(text: '13800138000');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Text('Budget Guard', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text('限额驱动型记账存钱 App\n3 秒记账，实时预算预警。'),
              const SizedBox(height: 24),
              TextField(controller: controller, decoration: const InputDecoration(labelText: '手机号')),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () async => context.read<AuthProvider>().login(controller.text),
                child: const SizedBox(width: double.infinity, child: Center(child: Text('验证码快捷登录（演示）'))),
              ),
              const SizedBox(height: 8),
              const Text('当前为 MVP 演示登录，后续可接入阿里云/腾讯云短信服务。'),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
