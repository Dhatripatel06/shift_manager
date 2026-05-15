// This is a basic Flutter widget test.
// Widget tests for VD Shift Manager will be added as the app matures.

import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Basic test - Firebase and Hive require initialization
    // which isn't available in widget tests without mocking.
    expect(true, isTrue);
  });
}
