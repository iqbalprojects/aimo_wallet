import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:aimo_wallet/core/security/secure_memory.dart';

void main() {
  group('SecureMemory', () {
    test('should clear Uint8List data', () {
      final data = Uint8List.fromList([1, 2, 3, 4, 5]);
      
      SecureMemory.clear(data);
      
      expect(data, equals([0, 0, 0, 0, 0]));
    });

    test('should clear empty Uint8List', () {
      final data = Uint8List(0);
      
      expect(() => SecureMemory.clear(data), returnsNormally);
    });

    test('should execute operation and clear data with withSecureData', () {
      final data = Uint8List.fromList([1, 2, 3, 4, 5]);
      
      final result = SecureMemory.withSecureData(data, (d) {
        // Verify data is accessible during operation
        expect(d, equals([1, 2, 3, 4, 5]));
        return d.length;
      });
      
      // Verify result is returned
      expect(result, equals(5));
      
      // Verify data is cleared after operation
      expect(data, equals([0, 0, 0, 0, 0]));
    });

    test('should clear data even if operation throws exception', () {
      final data = Uint8List.fromList([1, 2, 3, 4, 5]);
      
      expect(
        () => SecureMemory.withSecureData(data, (d) {
          throw Exception('Test exception');
        }),
        throwsException,
      );
      
      // Verify data is cleared even after exception
      expect(data, equals([0, 0, 0, 0, 0]));
    });

    test('should clear string data (best effort)', () {
      const testString = 'sensitive data';
      
      // This is best effort - we can't verify the original string is cleared
      // due to Dart's immutability, but we verify the method doesn't throw
      expect(() => SecureMemory.clearString(testString), returnsNormally);
    });
  });
}
