import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_rajasthan/app.dart';
import 'package:smart_rajasthan/i18n/app_locale.dart';

import 'helpers/fake_secure_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    installFakeSecureStorage();
  });

  tearDown(() {
    tearDownFakeSecureStorage();
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    await AppLocaleService.instance.initialize();
    await tester.pumpWidget(const SmartApp());
    expect(find.byType(SmartApp), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });
}
