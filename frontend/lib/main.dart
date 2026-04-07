import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'providers/auth_provider.dart';
import 'providers/record_provider.dart';
import 'providers/limit_provider.dart';
import 'providers/goal_provider.dart';
import 'providers/settings_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, RecordProvider>(
          create: (_) => RecordProvider(),
          update: (_, auth, recordProvider) {
            final provider = recordProvider ?? RecordProvider();
            provider.applyAuthContext(
              scope: auth.cacheScope,
              loggedIn: auth.loggedIn,
            );
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, LimitProvider>(
          create: (_) => LimitProvider(),
          update: (_, auth, limitProvider) {
            final provider = limitProvider ?? LimitProvider();
            provider.applyAuthContext(
              scope: auth.cacheScope,
              loggedIn: auth.loggedIn,
            );
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, GoalProvider>(
          create: (_) => GoalProvider(),
          update: (_, auth, goalProvider) {
            final provider = goalProvider ?? GoalProvider();
            provider.applyAuthContext(
              scope: auth.cacheScope,
              loggedIn: auth.loggedIn,
            );
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, SettingsProvider>(
          create: (_) => SettingsProvider(),
          update: (_, auth, settingsProvider) {
            final provider = settingsProvider ?? SettingsProvider();
            provider.applyAuthContext(
              scope: auth.cacheScope,
              loggedIn: auth.loggedIn,
            );
            return provider;
          },
        ),
      ],
      child: const BudgetGuardApp(),
    ),
  );
}
