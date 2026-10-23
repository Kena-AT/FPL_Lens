import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpl_lens/features/settings/screens/notifications_screen.dart';

void main() {
  Widget wrapNotifications() {
    return const ProviderScope(
      child: MaterialApp(
        home: NotificationsScreen(),
      ),
    );
  }

  group('P18 NotificationsScreen', () {
    testWidgets('Renders deadline reminders, chips, and injury alerts toggle', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrapNotifications());
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('DEADLINE REMINDERS'), findsOneWidget);
      expect(find.text('Remind me before deadline'), findsOneWidget);
      expect(find.text('Reminder timing'), findsOneWidget);
      expect(find.text('INJURY ALERTS'), findsOneWidget);
      expect(find.text('Squad injury & status alerts'), findsOneWidget);

      // Verify timing chips: 1 hour, 3 hours, 6 hours, 12 hours, 24 hours
      expect(find.text('1 hour'), findsOneWidget);
      expect(find.text('3 hours'), findsOneWidget);
      expect(find.text('6 hours'), findsOneWidget);
      expect(find.text('12 hours'), findsOneWidget);
      expect(find.text('24 hours'), findsOneWidget);
    });

    testWidgets('Toggling deadline reminders hides timing selector', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrapNotifications());
      await tester.pumpAndSettle();

      expect(find.text('Reminder timing'), findsOneWidget);

      // Switch off deadline reminders
      final switches = find.byType(Switch);
      expect(switches, findsNWidgets(2));
      await tester.tap(switches.first);
      await tester.pumpAndSettle();

      // Timing options hidden when reminders off
      expect(find.text('Reminder timing'), findsNothing);
    });
  });
}
