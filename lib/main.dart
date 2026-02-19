import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_pages.dart';
import 'core/di/app_initializer.dart';
import 'core/security/secure_session_manager.dart';

/// Main entry point
///
/// CRITICAL: Must initialize dependency injection before running app
void main() async {
  // Ensure Flutter bindings initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependency injection
  // This registers all services, repositories, use cases, and controllers
  await AppInitializer.initialize();

  // Run app
  runApp(const AimoWalletApp());
}

class AimoWalletApp extends StatelessWidget {
  const AimoWalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Aimo Wallet',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      // Add lifecycle observer for security
      builder: (context, child) {
        return _AppLifecycleObserver(child: child!);
      },
    );
  }
}

/// App Lifecycle Observer
///
/// SECURITY: Clears sensitive data when app goes to background
class _AppLifecycleObserver extends StatefulWidget {
  final Widget child;

  const _AppLifecycleObserver({required this.child});

  @override
  State<_AppLifecycleObserver> createState() => _AppLifecycleObserverState();
}

class _AppLifecycleObserverState extends State<_AppLifecycleObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // SECURITY: Clear all secure sessions when app goes to background
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      SecureSessionManager.clearAllSessions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
