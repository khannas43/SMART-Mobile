import 'package:flutter_test/flutter_test.dart';
import 'package:smart_rajasthan/utils/raj_sso_aes.dart';

void main() {
  const key = r'R@j$S0@02{09}19#';

  group('RajSsoAes', () {
    test('encrypts non-empty password to Base64', () {
      final encrypted = RajSsoAes.encryptPassword('Test@123', key);
      expect(encrypted, isNotEmpty);
      expect(encrypted, isNot(contains('Test@123')));
    });

    test('same input produces same ciphertext (deterministic IV from key)', () {
      final a = RajSsoAes.encryptPassword('Smart@2024', key);
      final b = RajSsoAes.encryptPassword('Smart@2024', key);
      expect(a, equals(b));
    });

    test('empty password returns empty string', () {
      expect(RajSsoAes.encryptPassword('', key), isEmpty);
    });
  });
}
