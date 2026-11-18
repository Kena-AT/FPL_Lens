import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpl_lens/core/storage/secure_store.dart';
import 'package:fpl_lens/features/auth/providers/auth_provider.dart';
import 'package:fpl_lens/features/scan/screens/scan_squad_screen.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  Widget buildTestable(Widget child, {double width = 360.0}) {
    final secureStore = SecureStore();
    return ProviderScope(
      overrides: [
        secureStoreProvider.overrideWithValue(secureStore),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(width, 800)),
          child: child,
        ),
      ),
    );
  }

  group('P15 ScanSquadScreen Widget Tests', () {
    testWidgets('renders capture options and tips correctly at 360 dp', (tester) async {
      await tester.pumpWidget(buildTestable(const ScanSquadScreen(), width: 360.0));
      await tester.pumpAndSettle();

      expect(find.text('Scan squad'), findsOneWidget);
      expect(find.text('Take photo'), findsOneWidget);
      expect(find.text('Choose from gallery'), findsOneWidget);

      // Verify tips card
      expect(find.text('SCREENSHOT TIPS'), findsOneWidget);
      expect(find.text('Capture the full squad, all 15 players.'), findsOneWidget);
      expect(find.text('Keep the screen bright and avoid glare.'), findsOneWidget);
      expect(find.text('Use a full-screen capture, not a cropped image.'), findsOneWidget);
      expect(
        find.text('Nothing is sent to FPL Lens. The image goes only to your chosen provider.'),
        findsOneWidget,
      );
    });

    testWidgets('tips card can be toggled via tips icon', (tester) async {
      await tester.pumpWidget(buildTestable(const ScanSquadScreen(), width: 360.0));
      await tester.pumpAndSettle();

      expect(find.text('SCREENSHOT TIPS'), findsOneWidget);

      // Tap the tips icon in the app bar
      await tester.tap(find.byIcon(Icons.help_outline));
      await tester.pumpAndSettle();

      expect(find.text('SCREENSHOT TIPS'), findsNothing);

      // Tap again to show
      await tester.tap(find.byIcon(Icons.help_outline));
      await tester.pumpAndSettle();

      expect(find.text('SCREENSHOT TIPS'), findsOneWidget);
    });

    testWidgets('renders properly at 430 dp width', (tester) async {
      await tester.pumpWidget(buildTestable(const ScanSquadScreen(), width: 430.0));
      await tester.pumpAndSettle();

      expect(find.text('Scan squad'), findsOneWidget);
      expect(find.text('Take photo'), findsOneWidget);
      expect(find.text('Choose from gallery'), findsOneWidget);
    });
  });
}
