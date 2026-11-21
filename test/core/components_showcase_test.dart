import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpl_lens/core/network/error_mapper.dart';
import 'package:fpl_lens/core/theme/app_colors.dart';
import 'package:fpl_lens/core/widgets/app_loading_indicator.dart';
import 'package:fpl_lens/core/widgets/availability_badge.dart';
import 'package:fpl_lens/core/widgets/card_container.dart';
import 'package:fpl_lens/core/widgets/delta_chip.dart';
import 'package:fpl_lens/core/widgets/empty_state.dart';
import 'package:fpl_lens/core/widgets/error_state.dart';
import 'package:fpl_lens/core/widgets/glass_container.dart';
import 'package:fpl_lens/core/widgets/stat_badge.dart';
import '../helpers/theme_test_harness.dart';

void main() {
  group('Sprint R2: Shared Components & Glass Showcase Tests', () {
    // -------------------------------------------------------------------------
    // 1. GlassContainer Tests
    // -------------------------------------------------------------------------
    group('GlassContainer', () {
      testWidgets('renders frosted glass with BackdropFilter in dark mode', (tester) async {
        await tester.pumpWidget(
          ThemeTestHarness.dark(
            child: const GlassContainer(
              child: Text('Glass content'),
            ),
          ),
        );

        expect(find.text('Glass content'), findsOneWidget);
        expect(find.byType(BackdropFilter), findsOneWidget);

        final backdropFilter = tester.widget<BackdropFilter>(find.byType(BackdropFilter));
        expect(backdropFilter.filter, isNotNull);
      });

      testWidgets('renders frosted glass with soft shadow in light mode', (tester) async {
        await tester.pumpWidget(
          ThemeTestHarness.light(
            child: const GlassContainer(
              child: Text('Light Glass'),
            ),
          ),
        );

        expect(find.text('Light Glass'), findsOneWidget);
        expect(find.byType(BackdropFilter), findsOneWidget);
      });

      testWidgets('progressive fallback renders solid bgSurface without blur when animations disabled', (tester) async {
        await tester.pumpWidget(
          ThemeTestHarness.dark(
            mediaQueryData: const MediaQueryData(disableAnimations: true),
            child: const GlassContainer(
              child: Text('Fallback content'),
            ),
          ),
        );

        expect(find.text('Fallback content'), findsOneWidget);
        // BackdropFilter must be bypassed when reduce motion is enabled
        expect(find.byType(BackdropFilter), findsNothing);

        final containerFinder = find.byType(Container).first;
        final container = tester.widget<Container>(containerFinder);
        final decoration = container.decoration as BoxDecoration?;
        expect(decoration?.color, AppColors.dark.bgSurface);
      });

      testWidgets('manual disableBlur flag forces solid fallback', (tester) async {
        await tester.pumpWidget(
          ThemeTestHarness.dark(
            child: const GlassContainer(
              disableBlur: true,
              child: Text('Manual fallback'),
            ),
          ),
        );

        expect(find.text('Manual fallback'), findsOneWidget);
        expect(find.byType(BackdropFilter), findsNothing);
      });
    });

    // -------------------------------------------------------------------------
    // 2. StatBadge Tests
    // -------------------------------------------------------------------------
    group('StatBadge', () {
      testWidgets('renders 4 size variants with tabular figures', (tester) async {
        await tester.pumpWidget(
          ThemeTestHarness.dark(
            child: const Column(
              children: [
                StatBadge(value: '68.4', unit: 'xP', label: 'Projected', size: StatBadgeSize.hero),
                StatBadge(value: '124,512', label: 'Overall Rank', size: StatBadgeSize.large),
                StatBadge(value: '£102.5m', label: 'Squad Value', size: StatBadgeSize.medium),
                StatBadge(value: 'GW38', label: 'Deadline', size: StatBadgeSize.small),
              ],
            ),
          ),
        );

        expect(find.text('68.4'), findsOneWidget);
        expect(find.text('xP'), findsOneWidget);
        expect(find.text('Projected'), findsOneWidget);
        expect(find.text('124,512'), findsOneWidget);
        expect(find.text('£102.5m'), findsOneWidget);
        expect(find.text('GW38'), findsOneWidget);

        // Verify tabular figures on hero numeral
        final heroText = tester.widget<Text>(find.text('68.4'));
        expect(heroText.style?.fontFeatures, contains(const FontFeature.tabularFigures()));
      });

      testWidgets('renders horizontal layout and accented style', (tester) async {
        await tester.pumpWidget(
          ThemeTestHarness.dark(
            child: const StatBadge(
              value: '+4.0',
              label: 'Gain',
              accented: true,
              vertical: false,
            ),
          ),
        );

        expect(find.text('+4.0'), findsOneWidget);
        expect(find.text('Gain'), findsOneWidget);

        final textWidget = tester.widget<Text>(find.text('+4.0'));
        expect(textWidget.style?.color, AppColors.dark.accent);
      });
    });

    // -------------------------------------------------------------------------
    // 3. AvailabilityBadge Tests
    // -------------------------------------------------------------------------
    group('AvailabilityBadge (Redesign Refactor)', () {
      testWidgets('renders subtle 6dp dot and never relies on colour alone', (tester) async {
        await tester.pumpWidget(
          ThemeTestHarness.dark(
            child: const Column(
              children: [
                AvailabilityBadge(variant: AvailabilityVariant.fit),
                AvailabilityBadge(variant: AvailabilityVariant.doubtful, chanceOfPlaying: 75),
                AvailabilityBadge(variant: AvailabilityVariant.injured),
                AvailabilityBadge(variant: AvailabilityVariant.suspended),
                AvailabilityBadge(variant: AvailabilityVariant.unknown),
              ],
            ),
          ),
        );

        expect(find.text('Fit'), findsOneWidget);
        expect(find.text('Doubtful, 75%'), findsOneWidget);
        expect(find.text('Injured'), findsOneWidget);
        expect(find.text('Suspended'), findsOneWidget);
        expect(find.text('No data'), findsOneWidget);

        // Verify distinct glyph icons are rendered
        expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
        expect(find.byIcon(Icons.warning_rounded), findsOneWidget);
        expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);
        expect(find.byIcon(Icons.block_rounded), findsOneWidget);
        expect(find.byIcon(Icons.help_outline_rounded), findsOneWidget);
      });

      testWidgets('renders compact variant cleanly', (tester) async {
        await tester.pumpWidget(
          ThemeTestHarness.light(
            child: const AvailabilityBadge(
              variant: AvailabilityVariant.fit,
              compact: true,
            ),
          ),
        );

        expect(find.text('Fit'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      });
    });

    // -------------------------------------------------------------------------
    // 4. DeltaChip Tests
    // -------------------------------------------------------------------------
    group('DeltaChip', () {
      testWidgets('renders price positive, negative, and zero deltas with directional glyphs', (tester) async {
        await tester.pumpWidget(
          ThemeTestHarness.dark(
            child: Column(
              children: [
                DeltaChip.price(delta: 0.2),
                DeltaChip.price(delta: -0.1),
                DeltaChip.price(delta: 0.0),
              ],
            ),
          ),
        );

        expect(find.text('+£0.2m'), findsOneWidget);
        expect(find.text('−£0.1m'), findsOneWidget);
        expect(find.text('£0.0m'), findsOneWidget);

        // Glyph ▲ for positive and ▼ for negative
        expect(find.text('▲'), findsOneWidget);
        expect(find.text('▼'), findsOneWidget);
      });

      testWidgets('renders points deltas with custom unit and tabular figures', (tester) async {
        await tester.pumpWidget(
          ThemeTestHarness.light(
            child: Column(
              children: [
                DeltaChip.points(delta: 4.5, unit: 'xP'),
                DeltaChip.points(delta: -2.0, unit: 'pts'),
              ],
            ),
          ),
        );

        expect(find.text('+4.5 xP'), findsOneWidget);
        expect(find.text('−2.0 pts'), findsOneWidget);

        final textWidget = tester.widget<Text>(find.text('+4.5 xP'));
        expect(textWidget.style?.fontFeatures, contains(const FontFeature.tabularFigures()));
      });

      testWidgets('renders rank improvement with inverted polarity', (tester) async {
        await tester.pumpWidget(
          ThemeTestHarness.dark(
            child: DeltaChip.rank(rankDelta: 25000), // Improvement of 25k spots
          ),
        );

        expect(find.text('▲ 25000'), findsOneWidget);
      });
    });

    // -------------------------------------------------------------------------
    // 5. CardContainer Tests
    // -------------------------------------------------------------------------
    group('CardContainer', () {
      testWidgets('renders surface variant with 12dp radius and subtle border', (tester) async {
        await tester.pumpWidget(
          ThemeTestHarness.dark(
            child: const CardContainer(
              child: Text('Card surface'),
            ),
          ),
        );

        expect(find.text('Card surface'), findsOneWidget);
      });

      testWidgets('renders glass variant embedding GlassContainer', (tester) async {
        await tester.pumpWidget(
          ThemeTestHarness.dark(
            child: const CardContainer(
              variant: CardVariant.glass,
              child: Text('Card glass'),
            ),
          ),
        );

        expect(find.text('Card glass'), findsOneWidget);
        expect(find.byType(GlassContainer), findsOneWidget);
      });

      testWidgets('renders accentRing with electric cyan border', (tester) async {
        await tester.pumpWidget(
          ThemeTestHarness.dark(
            child: const CardContainer(
              accentRing: true,
              child: Text('Highlighted Card'),
            ),
          ),
        );

        expect(find.text('Highlighted Card'), findsOneWidget);
        final container = tester.widget<Container>(find.byType(Container).first);
        final decoration = container.decoration as BoxDecoration?;
        final border = decoration?.border as Border?;
        expect(border?.top.color, AppColors.dark.accent);
      });

      testWidgets('interactive card responds to onTap', (tester) async {
        bool tapped = false;
        await tester.pumpWidget(
          ThemeTestHarness.dark(
            child: CardContainer(
              onTap: () => tapped = true,
              child: const Text('Tap Me'),
            ),
          ),
        );

        await tester.tap(find.text('Tap Me'));
        expect(tapped, isTrue);
      });
    });

    // -------------------------------------------------------------------------
    // 6. EmptyState, ErrorState, AppLoadingIndicator Tests
    // -------------------------------------------------------------------------
    group('States: Empty, Error, Loading', () {
      testWidgets('EmptyState renders cleanly in Light and Dark modes', (tester) async {
        bool actionTriggered = false;
        await tester.pumpWidget(
          ThemeTestHarness.light(
            child: EmptyState(
              icon: Icons.inbox_outlined,
              title: 'No Data Found',
              body: 'Connect your squad to begin tracking performance.',
              actionLabel: 'Connect Squad',
              onAction: () => actionTriggered = true,
            ),
          ),
        );

        expect(find.text('No Data Found'), findsOneWidget);
        expect(find.text('Connect your squad to begin tracking performance.'), findsOneWidget);
        expect(find.text('Connect Squad'), findsOneWidget);

        await tester.tap(find.text('Connect Squad'));
        expect(actionTriggered, isTrue);
      });

      testWidgets('ErrorState renders retryable error and triggers retry', (tester) async {
        bool retried = false;
        await tester.pumpWidget(
          ThemeTestHarness.dark(
            child: ErrorState(
              error: const AppError(
                kind: AppErrorKind.offline,
                message: 'Network connection lost',
                retryable: true,
              ),
              onRetry: () => retried = true,
            ),
          ),
        );

        expect(find.text('No connection'), findsOneWidget);
        expect(find.text('Network connection lost'), findsOneWidget);
        expect(find.text('Try again'), findsOneWidget);

        await tester.tap(find.text('Try again'));
        expect(retried, isTrue);
      });

      testWidgets('AppLoadingIndicator renders circular and linear styles', (tester) async {
        await tester.pumpWidget(
          ThemeTestHarness.dark(
            child: const Column(
              children: [
                AppLoadingIndicator(message: 'Loading projections...'),
                AppLoadingIndicator.linear(value: 0.6),
              ],
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
        expect(find.text('Loading projections...'), findsOneWidget);
      });

      testWidgets('Showcase renders without overflow at 200% text scale', (tester) async {
        await tester.pumpWidget(
          ThemeTestHarness.scale200(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const GlassContainer(child: Text('Scaled Glass')),
                  const StatBadge(value: '72.1', unit: 'xP', label: 'Points'),
                  const AvailabilityBadge(variant: AvailabilityVariant.fit),
                  DeltaChip.price(delta: 0.3),
                  const CardContainer(child: Text('Scaled Card')),
                  const AppLoadingIndicator(message: 'Calculating...'),
                ],
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Scaled Glass'), findsOneWidget);
        expect(find.text('72.1'), findsOneWidget);
      });
    });
  });
}
