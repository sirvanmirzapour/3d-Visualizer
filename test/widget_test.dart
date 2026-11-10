import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:magnetic_field_scanner/main.dart';

void main() {
  testWidgets('renders dashboard shell', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MagneticFieldScannerApp()));

    // Pump a few frames instead of pumpAndSettle (some offstage tabs keep an
    // indeterminate spinner animating, which would make settle() time out).
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Live Scan'), findsWidgets);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
