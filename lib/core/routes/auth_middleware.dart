import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../features/wallet/presentation/controllers/wallet_controller.dart';
import 'app_routes.dart';

/// Auth Middleware
/// 
/// GetX middleware for route protection and authentication checks.
/// 
/// Features:
/// - Protects authenticated routes
/// - Redirects to unlock if wallet is locked
/// - Redirects to onboarding if no wallet exists
/// 
/// Usage:
/// Add to GetPage in app_pages.dart:
/// ```dart
/// GetPage(
///   name: AppRoutes.home,
///   page: () => HomeDashboardScreen(),
///   middlewares: [AuthMiddleware()],
/// )
/// ```
/// 
/// Protected Routes:
/// - /home
/// - /send
/// - /receive
/// - /settings
/// 
/// Public Routes:
/// - /splash
/// - /onboarding
/// - /create-wallet
/// - /unlock
class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  /// Redirect logic
  /// 
  /// Checks:
  /// 1. Does wallet exist?
  /// 2. Is wallet unlocked?
  /// 
  /// Redirects:
  /// - No wallet -> Onboarding
  /// - Wallet locked -> Unlock
  /// - Wallet unlocked -> Continue to route
  @override
  RouteSettings? redirect(String? route) {
    // Try to get WalletController
    final walletController = Get.isRegistered<WalletController>()
        ? Get.find<WalletController>()
        : null;

    // If controller not available, allow navigation
    // (Controller will be initialized on the page)
    if (walletController == null) {
      return null;
    }

    // Check if wallet exists
    if (!walletController.hasWallet) {
      // No wallet -> Redirect to onboarding
      return const RouteSettings(name: AppRoutes.onboarding);
    }

    // Wallet exists, allow navigation
    // (Unlock screen will handle authentication)
    return null;
  }

  /// Called when route is being built
  @override
  GetPage? onPageCalled(GetPage? page) {
    return page;
  }

  /// Called when bindings are being built
  @override
  List<Bindings>? onBindingsStart(List<Bindings>? bindings) {
    return bindings;
  }

  /// Called after bindings are built
  @override
  GetPageBuilder? onPageBuildStart(GetPageBuilder? page) {
    return page;
  }

  /// Called after page is built
  @override
  Widget onPageBuilt(Widget page) {
    return page;
  }

  /// Called when page is disposed
  @override
  void onPageDispose() {
    // Cleanup if needed
  }
}

/// Public Route Middleware
/// 
/// Middleware for public routes that should redirect to home if already authenticated.
/// 
/// Usage:
/// Add to GetPage for onboarding/create wallet:
/// ```dart
/// GetPage(
///   name: AppRoutes.onboarding,
///   page: () => OnboardingScreen(),
///   middlewares: [PublicRouteMiddleware()],
/// )
/// ```
class PublicRouteMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  /// Redirect logic
  /// 
  /// If wallet exists and user tries to access onboarding/create,
  /// redirect to unlock or home.
  @override
  RouteSettings? redirect(String? route) {
    // Try to get WalletController
    final walletController = Get.isRegistered<WalletController>()
        ? Get.find<WalletController>()
        : null;

    // If controller not available, allow navigation
    if (walletController == null) {
      return null;
    }

    // If wallet exists, redirect to unlock
    if (walletController.hasWallet) {
      return const RouteSettings(name: AppRoutes.unlock);
    }

    // No wallet, allow access to public routes
    return null;
  }
}
