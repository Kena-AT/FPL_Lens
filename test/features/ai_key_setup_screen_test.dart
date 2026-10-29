import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpl_lens/core/storage/secure_store.dart';
import 'package:fpl_lens/core/widgets/app_button.dart';
import 'package:fpl_lens/features/auth/providers/auth_provider.dart';
import 'package:fpl_lens/features/settings/screens/ai_key_screen.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  Widget buildTestable(Widget child, {double width = 360.0, SecureStore? store}) {
    final secureStore = store ?? SecureStore();
    return ProviderScope(
      overrides: [
        secureStoreProvider.overrideWithValue(secureStore),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(width, 1600)),
          child: child,
        ),
      ),
    );
  }

  group('P17 AiKeySetupScreen Widget Tests', () {
    testWidgets('renders all 6 providers and disclosure notice verbatim', (tester) async {
      tester.view.physicalSize = const Size(360, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestable(const AiKeySetupScreen(), width: 360.0));
      await tester.pumpAndSettle();

      expect(find.text('AI key for screenshots'), findsOneWidget);
      expect(
        find.text(
          'Screenshots are read by an AI model you choose. You provide the key, and it stays on this phone.',
        ),
        findsOneWidget,
      );

      // Verify all 6 providers
      expect(find.text('Google Gemini'), findsOneWidget);
      expect(find.text('Anthropic Claude'), findsOneWidget);
      expect(find.text('OpenAI'), findsOneWidget);
      expect(find.text('xAI Grok'), findsOneWidget);
      expect(find.text('NVIDIA NIM'), findsOneWidget);
      expect(find.text('OpenRouter'), findsOneWidget);

      // Verify disclosure verbatim
      expect(
        find.text(
          'FPL Lens sends your screenshot and the extraction prompt directly from your phone to the provider you choose. '
          'We do not receive, store or see your key, your screenshot or the provider\'s response. '
          'The provider\'s terms govern how it handles your data. '
          'The quality of what the model returns is the responsibility of the provider and the model, not FPL Lens. '
          'We check only that the extracted names match players in the FPL database.',
        ),
        findsOneWidget,
      );

      expect(find.text('Draft wording'), findsOneWidget);
      expect(find.text('I understand'), findsOneWidget);
      expect(find.text('Validate and save'), findsOneWidget);
    });

    testWidgets('Validate and save button is disabled until key entered and checkbox ticked', (tester) async {
      tester.view.physicalSize = const Size(360, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestable(const AiKeySetupScreen(), width: 360.0));
      await tester.pumpAndSettle();

      // Find Validate and save button
      final saveBtnFinder = find.widgetWithText(AppButton, 'Validate and save');
      AppButton btn = tester.widget(saveBtnFinder);
      expect(btn.onPressed, isNull);

      // Enter API key
      final fieldFinder = find.byType(TextField);
      await tester.enterText(fieldFinder, 'AIzaSyTestKey1234567890abcdefABCDEF');
      await tester.pumpAndSettle();

      // Still disabled because checkbox not ticked
      btn = tester.widget(saveBtnFinder);
      expect(btn.onPressed, isNull);

      // Tap "I understand"
      await tester.tap(find.text('I understand'));
      await tester.pumpAndSettle();

      // Now enabled
      btn = tester.widget(saveBtnFinder);
      expect(btn.onPressed, isNotNull);
    });

    testWidgets('renders properly at 430 dp width', (tester) async {
      tester.view.physicalSize = const Size(430, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestable(const AiKeySetupScreen(), width: 430.0));
      await tester.pumpAndSettle();

      expect(find.text('AI key for screenshots'), findsOneWidget);
      expect(find.text('Google Gemini'), findsOneWidget);
      expect(find.text('Validate and save'), findsOneWidget);
    });
  });
}
