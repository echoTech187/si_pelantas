import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sipelantas_polri_mojokerto/main.dart';

void main() {
  testWidgets('SiPelantasPolriApp basic smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SiPelantasPolriApp()));
    expect(find.byType(SiPelantasPolriApp), findsOneWidget);
  });
}
