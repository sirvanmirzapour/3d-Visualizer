import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:magnetic_field_scanner/main.dart';

void main() {
  testWidgets('renders dashboard shell', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MagneticFieldScannerApp()));
    await tester.pumpAndSettle();

    expect(find.text('Magnetic Scanner'), findsWidgets);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Live Scan'), findsWidgets);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
