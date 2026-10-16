import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpl_lens/app/app.dart';

void main() {
  testWidgets('FplLensApp launches and builds widget tree', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: FplLensApp(),
      ),
    );

    expect(find.byType(FplLensApp), findsOneWidget);
  });
}
