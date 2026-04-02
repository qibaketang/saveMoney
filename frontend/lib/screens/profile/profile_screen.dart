import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../limits/limits_screen.dart';
import '../records/records_screen.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().profile;
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(user.nickname),
              subtitle: Text(user.phone),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.tune),
                  title: const Text('限额设置'),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LimitsScreen())),
                ),
                ListTile(
                  leading: const Icon(Icons.receipt_long),
                  title: const Text('消费记录'),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecordsScreen())),
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('提醒与偏好'),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: () => context.read<AuthProvider>().logout(),
            child: const Text('退出登录'),
          ),
        ],
      ),
    );
  }
}
