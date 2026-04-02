import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('接近限额提醒（80%）'),
            value: settings.limitAlert,
            onChanged: (value) => context.read<SettingsProvider>().update(limitAlertValue: value),
          ),
          SwitchListTile(
            title: const Text('超过限额提醒（100%）'),
            value: settings.overLimitAlert,
            onChanged: (value) => context.read<SettingsProvider>().update(overLimitAlertValue: value),
          ),
          SwitchListTile(
            title: const Text('推送通知'),
            value: settings.pushNotification,
            onChanged: (value) => context.read<SettingsProvider>().update(pushNotificationValue: value),
          ),
          SwitchListTile(
            title: const Text('短信提醒'),
            value: settings.smsNotification,
            onChanged: (value) => context.read<SettingsProvider>().update(smsNotificationValue: value),
          ),
          SwitchListTile(
            title: const Text('快捷记账模式'),
            value: settings.quickLedger,
            onChanged: (value) => context.read<SettingsProvider>().update(quickLedgerValue: value),
          ),
        ],
      ),
    );
  }
}
