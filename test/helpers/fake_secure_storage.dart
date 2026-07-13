import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

final Map<String, String> _memoryStore = {};

/// Registers an in-memory platform channel handler for flutter_secure_storage.
void installFakeSecureStorage() {
  TestWidgetsFlutterBinding.ensureInitialized();
  _memoryStore.clear();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, (call) async {
    final args = Map<String, dynamic>.from(call.arguments as Map);
    switch (call.method) {
      case 'read':
        return _memoryStore[args['key'] as String];
      case 'write':
        _memoryStore[args['key'] as String] = args['value'] as String;
        return null;
      case 'delete':
        _memoryStore.remove(args['key'] as String);
        return null;
      case 'deleteAll':
        _memoryStore.clear();
        return null;
      case 'containsKey':
        return _memoryStore.containsKey(args['key'] as String);
      default:
        return null;
    }
  });
}

void tearDownFakeSecureStorage() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, null);
  _memoryStore.clear();
}
