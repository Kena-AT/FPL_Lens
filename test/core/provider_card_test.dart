import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpl_lens/core/widgets/provider_card.dart';

void main() {
  Widget buildTestable(Widget child, {double width = 360.0}) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: child,
          ),
        ),
      ),
    );
  }

  group('D19 ProviderCard Widget Tests', () {
    testWidgets('renders selectable state correctly at 360 dp', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        buildTestable(
          ProviderCard(
            providerId: 'google_gemini',
            providerName: 'Google Gemini',
            modelName: 'gemini-3.5-flash-lite',
            isSelected: false,
            supportsVision: true,
            onTap: () => tapped = true,
          ),
          width: 360.0,
        ),
      );

      expect(find.text('Google Gemini'), findsOneWidget);
      expect(find.text('Default: gemini-3.5-flash-lite'), findsOneWidget);
      expect(find.text('Vision'), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

      await tester.tap(find.text('Google Gemini'));
      expect(tapped, isTrue);
    });

    testWidgets('renders selected state correctly', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const ProviderCard(
            providerId: 'anthropic_claude',
            providerName: 'Anthropic Claude',
            modelName: 'claude-3-5-sonnet',
            isSelected: true,
            supportsVision: true,
          ),
        ),
      );

      expect(find.text('Anthropic Claude'), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) => w is ProviderCard && w.isSelected),
        findsOneWidget,
      );
    });

    testWidgets('renders validated state with date', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const ProviderCard(
            providerId: 'openai',
            providerName: 'OpenAI',
            modelName: 'gpt-4o-mini',
            isSelected: false,
            isValidated: true,
            validationDate: '23/10/2026',
          ),
        ),
      );

      expect(find.text('Validated 23/10/2026'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('renders failed state with error message', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const ProviderCard(
            providerId: 'xai_grok',
            providerName: 'xAI Grok',
            modelName: 'grok-2-vision',
            isSelected: true,
            errorMessage: 'That key was rejected by the provider.',
          ),
        ),
      );

      expect(find.text('That key was rejected by the provider.'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('renders vision unsupported state correctly at 430 dp', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const ProviderCard(
            providerId: 'text_only_provider',
            providerName: 'Text Only LLM',
            modelName: 'text-v1',
            supportsVision: false,
          ),
          width: 430.0,
        ),
      );

      expect(find.text('No vision'), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });
  });
}
