import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpl_lens/core/network/error_mapper.dart';
import 'package:fpl_lens/core/widgets/app_button.dart';
import 'package:fpl_lens/core/widgets/app_text_field.dart';
import 'package:fpl_lens/core/widgets/code_input.dart';
import 'package:fpl_lens/core/widgets/confirm_sheet.dart';
import 'package:fpl_lens/core/widgets/disclosure_notice.dart';
import 'package:fpl_lens/core/widgets/empty_state.dart';
import 'package:fpl_lens/core/widgets/error_state.dart';
import 'package:fpl_lens/core/widgets/team_id_field.dart';

void main() {
  Widget wrapWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('Shared Widgets', () {
    testWidgets('AppButton renders label and handles tap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        wrapWidget(
          AppButton(
            label: 'Submit',
            onPressed: () => tapped = true,
          ),
        ),
      );

      expect(find.text('Submit'), findsOneWidget);
      await tester.tap(find.byType(AppButton));
      expect(tapped, isTrue);
    });

    testWidgets('AppButton shows spinner and disables tap when loading', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        wrapWidget(
          AppButton(
            label: 'Submit',
            isLoading: true,
            onPressed: () => tapped = true,
          ),
        ),
      );

      expect(find.text('Submit'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byType(AppButton));
      expect(tapped, isFalse);
    });

    testWidgets('AppTextField displays label above field and shows error', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          const AppTextField(
            label: 'Email Address',
            error: 'Invalid email',
          ),
        ),
      );

      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Invalid email'), findsOneWidget);
    });

    testWidgets('DisclosureNotice renders exact legal disclaimer verbatim', (tester) async {
      await tester.pumpWidget(wrapWidget(const DisclosureNotice()));

      expect(
        find.text(
          'FPL Lens is an independent analytics tool. It is not affiliated with, endorsed by, or sponsored by the Football Association Premier League Limited or Fantasy Premier League.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('CodeInput accepts 6 digits and notifies completion', (tester) async {
      String? completedCode;
      await tester.pumpWidget(
        wrapWidget(
          CodeInput(
            onCompleted: (code) => completedCode = code,
          ),
        ),
      );

      expect(find.byType(TextField), findsNWidgets(6));
      await tester.enterText(find.byType(TextField).at(0), '1');
      await tester.enterText(find.byType(TextField).at(1), '2');
      await tester.enterText(find.byType(TextField).at(2), '3');
      await tester.enterText(find.byType(TextField).at(3), '4');
      await tester.enterText(find.byType(TextField).at(4), '5');
      await tester.enterText(find.byType(TextField).at(5), '6');
      await tester.pump();

      expect(completedCode, '123456');
    });

    testWidgets('TeamIdField debounces lookup query by 500ms', (tester) async {
      int? queriedId;
      await tester.pumpWidget(
        wrapWidget(
          TeamIdField(
            onValidate: (id) async {
              queriedId = id;
              return TeamIdStatus.valid;
            },
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '987654');
      expect(queriedId, isNull);

      // Advance by 300ms (still within debounce)
      await tester.pump(const Duration(milliseconds: 300));
      expect(queriedId, isNull);

      // Advance past 500ms debounce
      await tester.pump(const Duration(milliseconds: 250));
      expect(queriedId, 987654);
    });

    testWidgets('ConfirmSheet presents confirmation and dismiss actions', (tester) async {
      bool confirmed = false;
      bool cancelled = false;

      await tester.pumpWidget(
        wrapWidget(
          ConfirmSheet(
            title: 'Delete Account',
            body: 'Are you sure?',
            confirmLabel: 'Confirm Delete',
            onConfirm: () => confirmed = true,
            onCancel: () => cancelled = true,
          ),
        ),
      );

      expect(find.text('Delete Account'), findsOneWidget);
      expect(find.text('Are you sure?'), findsOneWidget);

      await tester.tap(find.text('Confirm Delete'));
      expect(confirmed, isTrue);

      await tester.tap(find.text('Cancel'));
      expect(cancelled, isTrue);
    });

    testWidgets('EmptyState and ErrorState display messages and action buttons', (tester) async {
      bool retried = false;
      await tester.pumpWidget(
        wrapWidget(
          ErrorState(
            error: const AppError(
              kind: AppErrorKind.server,
              message: 'Something went wrong on our side. Try again.',
              retryable: true,
            ),
            onRetry: () => retried = true,
          ),
        ),
      );

      expect(find.text('Something went wrong on our side. Try again.'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      expect(retried, isTrue);

      await tester.pumpWidget(
        wrapWidget(
          const EmptyState(
            icon: Icons.inbox,
            title: 'No Data',
            body: 'Nothing here yet',
          ),
        ),
      );

      expect(find.text('No Data'), findsOneWidget);
      expect(find.text('Nothing here yet'), findsOneWidget);
    });
  });
}
