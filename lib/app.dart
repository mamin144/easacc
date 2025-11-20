import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/view/settings_page.dart';
import 'features/webview/view/webview_page.dart';

class EasaccApp extends ConsumerWidget {
  const EasaccApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EASACC Browser',
      theme: AppTheme.light,
      initialRoute: AppRoutes.settings,
      routes: {
        AppRoutes.settings: (_) => const SettingsPage(),
        AppRoutes.webView: (_) => const WebViewPage(),
      },
    );
  }
}
