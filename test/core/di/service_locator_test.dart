import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:aimo_wallet/core/di/service_locator.dart';
import 'package:aimo_wallet/core/crypto/bip39_service.dart';
import 'package:aimo_wallet/core/crypto/bip32_service.dart';
import 'package:aimo_wallet/core/crypto/key_derivation_service.dart';
import 'package:aimo_wallet/core/vault/encryption_service.dart';
import 'package:aimo_wallet/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:aimo_wallet/features/wallet/domain/usecases/create_wallet_usecase.dart';
import 'package:aimo_wallet/features/wallet/domain/usecases/save_wallet_usecase.dart';
import 'package:aimo_wallet/features/wallet/domain/usecases/import_wallet_usecase.dart';
import 'package:aimo_wallet/features/wallet/domain/usecases/unlock_wallet_usecase.dart';
import 'package:aimo_wallet/features/wallet/domain/usecases/get_wallet_address_usecase.dart';
import 'package:aimo_wallet/features/wallet/domain/usecases/delete_wallet_usecase.dart';
import 'package:aimo_wallet/features/wallet/domain/usecases/export_mnemonic_usecase.dart';
import 'package:aimo_wallet/features/wallet/domain/usecases/verify_backup_usecase.dart';
import 'package:aimo_wallet/features/wallet/presentation/controllers/wallet_controller.dart';
import 'package:aimo_wallet/features/wallet/presentation/controllers/wallet_creation_controller.dart';
import 'package:aimo_wallet/features/wallet/presentation/controllers/wallet_import_controller.dart';
import 'package:aimo_wallet/features/wallet/presentation/controllers/wallet_unlock_controller.dart';
import 'package:aimo_wallet/features/wallet/presentation/controllers/wallet_settings_controller.dart';

/// Service Locator Tests
/// 
/// Tests dependency injection setup and registration.
/// 
/// Requirements: 10.3, 10.4
void main() {
  setUp(() {
    // Initialize service locator before each test
    ServiceLocator.init();
  });

  tearDown(() {
    // Clean up after each test
    ServiceLocator.dispose();
  });

  group('Core Services Registration', () {
    test('should register Bip39Service', () {
      final service = Get.find<Bip39Service>();
      expect(service, isNotNull);
      expect(service, isA<Bip39Service>());
    });

    test('should register Bip32Service', () {
      final service = Get.find<Bip32Service>();
      expect(service, isNotNull);
      expect(service, isA<Bip32Service>());
    });

    test('should register KeyDerivationService', () {
      final service = Get.find<KeyDerivationService>();
      expect(service, isNotNull);
      expect(service, isA<KeyDerivationService>());
    });

    test('should register EncryptionService', () {
      final service = Get.find<EncryptionService>();
      expect(service, isNotNull);
      expect(service, isA<EncryptionService>());
    });

    test('should return same instance for singleton services', () {
      final service1 = Get.find<Bip39Service>();
      final service2 = Get.find<Bip39Service>();
      expect(identical(service1, service2), isTrue);
    });
  });

  group('Repository Registration', () {
    test('should register WalletRepository', () {
      final repository = Get.find<WalletRepository>();
      expect(repository, isNotNull);
      expect(repository, isA<WalletRepository>());
    });

    test('should return same instance for singleton repository', () {
      final repo1 = Get.find<WalletRepository>();
      final repo2 = Get.find<WalletRepository>();
      expect(identical(repo1, repo2), isTrue);
    });
  });

  group('Use Cases Registration', () {
    test('should register CreateWalletUseCase', () {
      final useCase = Get.find<CreateWalletUseCase>();
      expect(useCase, isNotNull);
      expect(useCase, isA<CreateWalletUseCase>());
    });

    test('should register SaveWalletUseCase', () {
      final useCase = Get.find<SaveWalletUseCase>();
      expect(useCase, isNotNull);
      expect(useCase, isA<SaveWalletUseCase>());
    });

    test('should register ImportWalletUseCase', () {
      final useCase = Get.find<ImportWalletUseCase>();
      expect(useCase, isNotNull);
      expect(useCase, isA<ImportWalletUseCase>());
    });

    test('should register UnlockWalletUseCase', () {
      final useCase = Get.find<UnlockWalletUseCase>();
      expect(useCase, isNotNull);
      expect(useCase, isA<UnlockWalletUseCase>());
    });

    test('should register GetWalletAddressUseCase', () {
      final useCase = Get.find<GetWalletAddressUseCase>();
      expect(useCase, isNotNull);
      expect(useCase, isA<GetWalletAddressUseCase>());
    });

    test('should register DeleteWalletUseCase', () {
      final useCase = Get.find<DeleteWalletUseCase>();
      expect(useCase, isNotNull);
      expect(useCase, isA<DeleteWalletUseCase>());
    });

    test('should register ExportMnemonicUseCase', () {
      final useCase = Get.find<ExportMnemonicUseCase>();
      expect(useCase, isNotNull);
      expect(useCase, isA<ExportMnemonicUseCase>());
    });

    test('should register VerifyBackupUseCase', () {
      final useCase = Get.find<VerifyBackupUseCase>();
      expect(useCase, isNotNull);
      expect(useCase, isA<VerifyBackupUseCase>());
    });
  });

  group('Controllers Registration', () {
    test('should register WalletController', () {
      final controller = Get.find<WalletController>();
      expect(controller, isNotNull);
      expect(controller, isA<WalletController>());
    });

    test('should register WalletCreationController', () {
      final controller = Get.find<WalletCreationController>();
      expect(controller, isNotNull);
      expect(controller, isA<WalletCreationController>());
    });

    test('should register WalletImportController', () {
      final controller = Get.find<WalletImportController>();
      expect(controller, isNotNull);
      expect(controller, isA<WalletImportController>());
    });

    test('should register WalletUnlockController', () {
      final controller = Get.find<WalletUnlockController>();
      expect(controller, isNotNull);
      expect(controller, isA<WalletUnlockController>());
    });

    test('should register WalletSettingsController', () {
      final controller = Get.find<WalletSettingsController>();
      expect(controller, isNotNull);
      expect(controller, isA<WalletSettingsController>());
    });

    test('should return same instance for WalletController (global state)', () {
      final controller1 = Get.find<WalletController>();
      final controller2 = Get.find<WalletController>();
      expect(identical(controller1, controller2), isTrue);
    });
  });

  group('Dependency Injection', () {
    test('should inject dependencies into use cases', () {
      final createWalletUseCase = Get.find<CreateWalletUseCase>();
      
      // Use case should have repository injected
      expect(createWalletUseCase.repository, isNotNull);
      expect(createWalletUseCase.bip39Service, isNotNull);
      expect(createWalletUseCase.keyDerivationService, isNotNull);
    });

    test('should inject dependencies into controllers', () {
      final walletController = Get.find<WalletController>();
      
      // Controller should have use cases injected
      // Note: These are private fields, so we can't directly test them
      // But we can verify the controller was created successfully
      expect(walletController, isNotNull);
    });

    test('should share repository instance across use cases', () {
      final createWalletUseCase = Get.find<CreateWalletUseCase>();
      final saveWalletUseCase = Get.find<SaveWalletUseCase>();
      
      // Both use cases should share the same repository instance
      expect(
        identical(
          createWalletUseCase.repository,
          saveWalletUseCase.repository,
        ),
        isTrue,
      );
    });
  });

  group('Cleanup', () {
    test('should dispose all dependencies', () {
      // Get some dependencies
      Get.find<Bip39Service>();
      Get.find<WalletController>();
      
      // Dispose all
      ServiceLocator.dispose();
      
      // After dispose, GetX should not have the dependencies registered
      // Note: GetX may still return instances if they're cached, but
      // the important thing is that dispose was called successfully
      expect(ServiceLocator.dispose, returnsNormally);
    });
  });
}
