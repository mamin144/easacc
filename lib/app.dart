import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/controller/auth_controller.dart';
import 'features/auth/state/auth_state.dart';
import 'features/auth/view/login_page.dart';
import 'features/settings/view/settings_page.dart';
import 'features/webview/view/webview_page.dart';

class EasaccApp extends StatelessWidget {
  const EasaccApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (previous, current) =>
          previous.isAuthenticated != current.isAuthenticated,
      listener: (context, next) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          final navigator = Navigator.maybeOf(context);
          if (navigator == null) {
            return;
          }

          if (next.isAuthenticated) {
            navigator.pushReplacementNamed(AppRoutes.settings);
          } else {
            navigator.pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginPage()),
              (route) => false,
            );
          }
        });
      },
      builder: (context, authState) {
        if (authState.isLoading) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'EASACC Browser',
            theme: AppTheme.light,
            home: const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final homeWidget = authState.isAuthenticated
            ? const SettingsPage()
            : const LoginPage();

        final routesMap = <String, WidgetBuilder>{
          AppRoutes.settings: (context) => const SettingsPage(),
          AppRoutes.webView: (context) => const WebViewPage(),
        };

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'EASACC Browser',
          theme: AppTheme.light,
          home: homeWidget,
          routes: routesMap,
          onUnknownRoute: (settings) {
            return MaterialPageRoute(builder: (_) => const LoginPage());
          },
        );
      },
    );
  }
}
