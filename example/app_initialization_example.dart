import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:aimo_wallet/core/di/app_initializer.dart';
import 'package:aimo_wallet/features/wallet/presentation/controllers/wallet_controller.dart';

/// Example: App Initialization
/// 
/// This example demonstrates how to initialize the app with dependency injection
/// and wallet state management.
/// 
/// Requirements: 7.1, 7.5, 10.3, 10.4
/// 
/// Usage:
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await AppInitializer.initialize();
///   runApp(const MyApp());
/// }
/// ```

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize app (dependency injection + wallet state)
  await AppInitializer.initialize();

  // Run app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Aimo Wallet',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get wallet controller (already initialized)
    final walletController = Get.find<WalletController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aimo Wallet'),
      ),
      body: Obx(() {
        // Show loading indicator during initialization
        if (walletController.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // Show error if initialization failed
        if (walletController.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  'Initialization Error',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  walletController.errorMessage!,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Retry initialization
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Retrying...')),
                    );
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Display wallet status
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Wallet status icon
              Icon(
                walletController.hasWallet ? Icons.account_balance_wallet : Icons.account_balance_wallet_outlined,
                size: 64,
                color: walletController.hasWallet ? Colors.green : Colors.grey,
              ),
              const SizedBox(height: 16),

              // Wallet status text
              Text(
                walletController.hasWallet ? 'Wallet Exists' : 'No Wallet',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),

              // Wallet address (if available)
              if (walletController.hasWallet && walletController.currentAddress.value.isNotEmpty) ...[
                const Text('Address:'),
                const SizedBox(height: 4),
                Text(
                  walletController.currentAddress.value,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Balance: ${walletController.balance} ETH',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 32),

              // Action buttons based on wallet existence
              ...walletController.hasWallet
                  ? [
                      ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Navigate to wallet screen')),
                          );
                        },
                        icon: const Icon(Icons.account_balance_wallet),
                        label: const Text('View Wallet'),
                      ),
                    ]
                  : [
                      ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Navigate to wallet creation screen')),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Create Wallet'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Navigate to wallet import screen')),
                          );
                        },
                        icon: const Icon(Icons.download),
                        label: const Text('Import Wallet'),
                      ),
                    ],
            ],
          ),
        );
      }),
    );
  }
}
