import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_theme.dart';
import 'package:skill_battles/core/presentation/widgets/app_text_field.dart';

void main() {
  late TextEditingController controller;
  late FocusNode focusNode;
  late GlobalKey<FormState> formKey;

  setUp(() {
    controller = TextEditingController();
    focusNode = FocusNode();
    formKey = GlobalKey<FormState>();
  });

  tearDown(() {
    controller.dispose();
    focusNode.dispose();
  });

  Future<void> pumpField(
    WidgetTester tester, {
    FormFieldValidator<String>? validator,
    String? helperText,
    String? errorText,
    bool passFocusNode = true,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: Form(
                key: formKey,
                child: AppTextField(
                  label: 'Email',
                  controller: controller,
                  focusNode: passFocusNode ? focusNode : null,
                  validator: validator,
                  helperText: helperText,
                  errorText: errorText,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('AppTextField', () {
    testWidgets('shows the label and the helper text', (
      WidgetTester tester,
    ) async {
      await pumpField(tester, helperText: 'We never share it');

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('We never share it'), findsOneWidget);
    });

    testWidgets('shows the validator error after validate', (
      WidgetTester tester,
    ) async {
      await pumpField(
        tester,
        validator: (String? value) =>
            (value ?? '').isEmpty ? 'Enter your email' : null,
      );
      expect(find.text('Enter your email'), findsNothing);

      final bool isValid = formKey.currentState!.validate();
      await tester.pump();

      expect(isValid, isFalse);
      expect(find.text('Enter your email'), findsOneWidget);
    });

    testWidgets('shows no error once the value is valid', (
      WidgetTester tester,
    ) async {
      await pumpField(
        tester,
        validator: (String? value) =>
            (value ?? '').isEmpty ? 'Enter your email' : null,
      );
      await tester.enterText(find.byType(TextFormField), 'a@b.co');

      final bool isValid = formKey.currentState!.validate();
      await tester.pump();

      expect(isValid, isTrue);
      expect(find.text('Enter your email'), findsNothing);
    });

    testWidgets('tapping the padding inside the box focuses the input', (
      WidgetTester tester,
    ) async {
      await pumpField(tester);
      expect(focusNode.hasFocus, isFalse);

      final Offset topLeft = tester.getTopLeft(find.byType(TextFormField));
      await tester.tapAt(topLeft + const Offset(4, 24));
      await tester.pump();

      expect(focusNode.hasFocus, isTrue);
    });

    testWidgets('tapping the label focuses the input (passed focus node)', (
      WidgetTester tester,
    ) async {
      await pumpField(tester);

      await tester.tap(find.text('Email'));
      await tester.pump();

      expect(focusNode.hasFocus, isTrue);
    });

    testWidgets('tapping the label focuses the input (own focus node)', (
      WidgetTester tester,
    ) async {
      await pumpField(tester, passFocusNode: false);
      final FocusNode own = tester
          .widget<EditableText>(find.byType(EditableText))
          .focusNode;
      expect(own, isNot(focusNode));
      expect(own.hasFocus, isFalse);

      await tester.tap(find.text('Email'));
      await tester.pump();

      expect(own.hasFocus, isTrue);
    });

    testWidgets('disposes only the focus node it owns', (
      WidgetTester tester,
    ) async {
      await pumpField(tester, passFocusNode: false);
      final FocusNode own = tester
          .widget<EditableText>(find.byType(EditableText))
          .focusNode;

      await tester.pumpWidget(const SizedBox.shrink());

      expect(() => own.addListener(() {}), throwsFlutterError);
      // The caller's node is still usable (tearDown disposes it).
      expect(() => focusNode.addListener(() {}), returnsNormally);
    });

    testWidgets('the label is merged into the field semantics', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpField(tester, helperText: 'We never share it');

      final SemanticsNode node = tester.getSemantics(find.byType(EditableText));

      expect(node.label, contains('Email'));
      handle.dispose();
    });

    testWidgets('draws a 1 px border at rest', (WidgetTester tester) async {
      await pumpField(tester);

      expect(
        find.byType(InputDecorator),
        paints..rrect(color: AppColors.border, strokeWidth: 1),
      );
    });

    testWidgets('draws a 1.5 px primary border when focused', (
      WidgetTester tester,
    ) async {
      await pumpField(tester);

      await tester.tap(find.byType(TextFormField));
      // One frame starts the border transition, the next one finishes it.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.byType(InputDecorator),
        paints..rrect(color: AppColors.primary, strokeWidth: 1.5),
      );

      // Unmount before tearDown disposes the focused node.
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('draws a 1.5 px danger border with an error', (
      WidgetTester tester,
    ) async {
      await pumpField(tester, errorText: 'Server says no');

      expect(find.text('Server says no'), findsOneWidget);
      expect(
        find.byType(InputDecorator),
        paints..rrect(color: AppColors.danger, strokeWidth: 1.5),
      );
    });
  });
}
