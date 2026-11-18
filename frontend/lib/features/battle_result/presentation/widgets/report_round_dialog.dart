import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/app/theme/app_shadows.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/markdown/markdown_spans.dart';
import 'package:skill_battles/core/presentation/overlay/app_overlay.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/core/presentation/widgets/app_eyebrow.dart';
import 'package:skill_battles/core/presentation/widgets/app_form.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';
import 'package:skill_battles/core/presentation/widgets/app_tappable.dart';
import 'package:skill_battles/core/presentation/widgets/app_text_input.dart';
import 'package:skill_battles/core/presentation/widgets/app_text_link.dart';
import 'package:skill_battles/features/battle_result/domain/entity/report_params_entity.dart';
import 'package:skill_battles/features/battle_result/domain/entity/report_reason.dart';

/// Asks for a report reason and comment; `null` when dismissed. Reporting
/// never reveals the correct answer and never changes the rating
/// (Paper: "19 Report question (modal)").
///
/// [eyebrow] is the caption ("Round 03 · SAT Math"), [prompt] the question.
Future<ReportParamsEntity?> showReportRoundDialog(
  BuildContext context, {
  required String battleId,
  required String roundId,
  required String eyebrow,
  required String prompt,
}) => showAppDialog<ReportParamsEntity>(
  context: context,
  barrierColor: AppColors.scrim,
  builder: (BuildContext dialogContext) => ReportRoundDialog(
    battleId: battleId,
    roundId: roundId,
    eyebrow: eyebrow,
    prompt: prompt,
  ),
);

final class ReportRoundDialog extends StatefulComponent {
  const ReportRoundDialog({
    required this.battleId,
    required this.roundId,
    required this.eyebrow,
    required this.prompt,
    super.key,
  });

  final String battleId;
  final String roundId;
  final String eyebrow;
  final String prompt;

  @override
  State<ReportRoundDialog> createState() => _ReportRoundDialogState();
}

final class _ReportRoundDialogState extends State<ReportRoundDialog> {
  late final GlobalStateKey<AppFormState> _formKey;
  late final TextEditingController _comment;
  late ReportReason _reason;

  static const Map<ReportReason, String> _labels = <ReportReason, String>{
    ReportReason.incorrectAnswer: 'The answer key may be wrong',
    ReportReason.unclearQuestion: 'The question is unclear',
    ReportReason.typo: "There's a typo",
    ReportReason.other: 'Something else',
  };

  static const int _promptPreviewLength = 40;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalStateKey<AppFormState>();
    _comment = TextEditingController();
    _reason = ReportReason.incorrectAnswer;
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  void _close() => closeAppDialog<ReportParamsEntity>(context);

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final String comment = _comment.text.trim();
    closeAppDialog<ReportParamsEntity>(
      context,
      ReportParamsEntity(
        battleId: component.battleId,
        roundId: component.roundId,
        reason: _reason,
        comment: comment.isEmpty ? null : comment,
      ),
    );
  }

  @override
  Component build(BuildContext context) {
    // The preview quotes the question as plain text: cutting Markdown or a
    // formula at a fixed length would leave half of its markup.
    final String plain = MarkdownSpans.plainText(component.prompt);
    final String prompt = plain.length > _promptPreviewLength
        ? '${plain.substring(0, _promptPreviewLength).trimRight()}…'
        : plain;
    final bool commentRequired = _reason == ReportReason.other;
    return div(
      classes: 'report-dialog',
      attributes: const <String, String>{'aria-labelledby': 'report-dialog-title'},
      <Component>[
        AppForm(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteractionIfError,
          onSubmit: _submit,
          child: div(classes: 'report-dialog__body', <Component>[
            div(classes: 'report-dialog__header', <Component>[
              div(classes: 'report-dialog__heading', <Component>[
                AppEyebrow(component.eyebrow),
                const h2(
                  id: 'report-dialog-title',
                  classes: 'report-dialog__title',
                  <Component>[Component.text('Report this question')],
                ),
              ]),
              AppTappable(
                onTap: _close,
                radius: 6,
                semanticLabel: 'Close',
                classes: 'report-dialog__close',
                child: const AppSvgIcon(AppIcons.close, width: 20, height: 20),
              ),
            ]),
            p(classes: 'report-dialog__intro', <Component>[
              Component.text(
                '"$prompt" — our content team reviews every report. It '
                "won't change ratings or reveal the answer.",
              ),
            ]),
            div(
              classes: 'report-dialog__reasons',
              attributes: const <String, String>{'role': 'group', 'aria-label': 'Reason'},
              <Component>[
                for (final ReportReason reason in ReportReason.values)
                  _ReasonTile(
                    label: _labels[reason]!,
                    note: reason == ReportReason.other ? ' (comment required)' : null,
                    isSelected: reason == _reason,
                    onTap: () => setState(() => _reason = reason),
                  ),
              ],
            ),
            div(classes: 'report-dialog__comment', <Component>[
              label(htmlFor: 'report-dialog-comment', classes: 'report-dialog__comment-label', <Component>[
                const span(<Component>[Component.text('Comment ')]),
                span(classes: 'report-dialog__comment-hint', <Component>[
                  Component.text(commentRequired ? '· required' : '· optional'),
                ]),
              ]),
              _CommentField(controller: _comment, isRequired: commentRequired),
            ]),
            div(classes: 'report-dialog__actions', <Component>[
              div(classes: 'report-dialog__cancel', <Component>[
                AppTextLink(
                  label: 'Cancel',
                  style: AppTextStyles.bodyMd.combine(
                    const Styles(color: AppColors.muted, fontWeight: FontWeight.w500),
                  ),
                  onPressed: _close,
                ),
              ]),
              AppButton(
                label: 'Send report',
                variant: AppButtonVariant.dark,
                size: AppButtonSize.small,
                onPressed: _submit,
              ),
            ]),
          ]),
        ),
      ],
    );
  }
}

/// A 48 px radio row: blue outline and filled ring when selected.
final class _ReasonTile extends StatelessComponent {
  const _ReasonTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.note,
  });

  final String label;
  final String? note;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Component build(BuildContext context) {
    final String? note = this.note;
    return AppTappable(
      onTap: onTap,
      radius: 10,
      isSelected: isSelected,
      semanticLabel: '$label${note ?? ''}',
      classes: isSelected ? 'report-reason report-reason--selected' : 'report-reason',
      child: Component.fragment(<Component>[
        const span(classes: 'report-reason__radio', <Component>[]),
        p(classes: 'report-reason__label', <Component>[
          span(<Component>[Component.text(label)]),
          if (note != null) span(classes: 'report-reason__note', <Component>[Component.text(note)]),
        ]),
      ]),
    );
  }
}

/// The comment box with a "48 / 1000" counter under its bottom edge.
final class _CommentField extends StatelessComponent {
  const _CommentField({required this.controller, required this.isRequired});

  final TextEditingController controller;
  final bool isRequired;

  @override
  Component build(BuildContext context) {
    return AppFormField<String>(
      initialValue: controller.text,
      validator: (String? value) => isRequired && (value?.trim() ?? '').isEmpty ? 'Describe the problem' : null,
      builder: (AppFormFieldState<String> field) =>
          _CommentInput(field: field, controller: controller, isRequired: isRequired),
    );
  }
}

final class _CommentInput extends StatelessComponent {
  const _CommentInput({
    required this.field,
    required this.controller,
    required this.isRequired,
  });

  final AppFormFieldState<String> field;
  final TextEditingController controller;
  final bool isRequired;

  @override
  Component build(BuildContext context) {
    final String? error = field.errorText;
    final int length = (field.value ?? '').length;
    return div(classes: 'report-comment', <Component>[
      textarea(
        id: 'report-dialog-comment',
        rows: 2,
        placeholder: isRequired ? 'Describe the problem' : null,
        classes: error == null ? 'report-comment__input' : 'report-comment__input report-comment__input--error',
        attributes: <String, String>{
          'maxlength': '${ReportParamsEntity.maxCommentLength}',
          if (error != null) 'aria-invalid': 'true',
          if (error != null) 'aria-describedby': 'report-dialog-comment-error',
        },
        events: <String, void Function(web.Event)>{
          'input': (web.Event event) {
            final String value = (event.target! as web.HTMLTextAreaElement).value;
            controller.text = value;
            field.didChange(value);
          },
        },
        const <Component>[],
      ),
      div(classes: 'report-comment__footer', <Component>[
        if (error != null)
          p(
            id: 'report-dialog-comment-error',
            classes: 'report-comment__error',
            attributes: const <String, String>{'aria-live': 'polite'},
            <Component>[Component.text(error)],
          ),
        span(classes: 'report-comment__counter', <Component>[
          Component.text('$length / ${ReportParamsEntity.maxCommentLength}'),
        ]),
      ]),
    ]);
  }
}

@css
List<StyleRule> get reportRoundDialogStyles => <StyleRule>[
  css('.report-dialog').styles(
    width: const Unit.pixels(520),
    maxWidth: const Unit.percent(100),
    maxHeight: const Unit.expression('calc(100vh - 48px)'),
    padding: const Padding.all(Unit.pixels(32)),
    boxSizing: BoxSizing.borderBox,
    radius: const BorderRadius.circular(Unit.pixels(20)),
    overflow: Overflow.auto,
    shadow: AppShadows.dialog,
    backgroundColor: AppColors.white,
  ),
  css('.report-dialog__body').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(22)),
  ),
  css('.report-dialog__header').styles(display: Display.flex, alignItems: AlignItems.start),
  css('.report-dialog__heading').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    flexDirection: FlexDirection.column,
    alignItems: AlignItems.start,
    gap: const Gap.row(Unit.pixels(8)),
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.report-dialog__title').combine(AppTextStyles.titleXlCompact).combine(const Styles(lineHeight: Unit.pixels(32))),
  css('.report-dialog__close').styles(flex: const Flex(shrink: 0)),
  css('.report-dialog__intro')
      .combine(AppTextStyles.bodyMd)
      .combine(const Styles(color: AppColors.muted, lineHeight: Unit.pixels(20))),
  css('.report-dialog__reasons').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(8)),
  ),
  css('.report-dialog__comment').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(6)),
  ),
  css('.report-dialog__comment-label')
      .styles(alignSelf: AlignSelf.start)
      .combine(AppTextStyles.bodySm)
      .combine(const Styles(fontWeight: FontWeight.w500)),
  css('.report-dialog__comment-hint').styles(color: AppColors.muted, fontWeight: FontWeight.w400),
  css('.report-dialog__actions').styles(
    display: Display.flex,
    justifyContent: JustifyContent.end,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(10)),
  ),
  css('.report-dialog__cancel').styles(
    display: Display.flex,
    height: const Unit.pixels(46),
    padding: const Padding.symmetric(horizontal: Unit.pixels(18)),
    alignItems: AlignItems.center,
  ),
  css('.report-reason').styles(
    display: Display.flex,
    height: const Unit.pixels(48),
    padding: const Padding.symmetric(horizontal: Unit.pixels(17)),
    boxSizing: BoxSizing.borderBox,
    border: Border.all(color: AppColors.border, width: const Unit.pixels(1)),
    radius: const BorderRadius.circular(Unit.pixels(10)),
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(12)),
    backgroundColor: AppColors.white,
  ),
  css('.report-reason--selected').styles(
    padding: const Padding.symmetric(horizontal: Unit.pixels(16)),
    border: Border.all(color: AppColors.primary, width: const Unit.pixels(2)),
    backgroundColor: AppColors.primarySurface,
  ),
  css('.report-reason__radio').styles(
    display: Display.block,
    width: const Unit.pixels(18),
    height: const Unit.pixels(18),
    boxSizing: BoxSizing.borderBox,
    border: Border.all(color: AppColors.borderStrong, width: const Unit.pixels(1.5)),
    radius: const BorderRadius.circular(Unit.percent(50)),
    flex: const Flex(shrink: 0),
  ),
  css('.report-reason--selected .report-reason__radio').styles(
    border: Border.all(color: AppColors.primary, width: const Unit.pixels(5)),
  ),
  css('.report-reason__label')
      .styles(
        minWidth: Unit.zero,
        flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
      )
      .combine(AppTextStyles.bodyLg),
  css('.report-reason--selected .report-reason__label').styles(fontWeight: FontWeight.w500),
  css('.report-reason__note').styles(color: AppColors.muted),
  css('.report-comment').styles(display: Display.flex, flexDirection: FlexDirection.column),
  css('.report-comment__input')
      .styles(
        display: Display.block,
        width: const Unit.percent(100),
        minHeight: const Unit.pixels(64),
        maxHeight: const Unit.pixels(104),
        padding: const Padding.symmetric(horizontal: Unit.pixels(13), vertical: Unit.pixels(11)),
        boxSizing: BoxSizing.borderBox,
        border: Border.all(color: AppColors.border, width: const Unit.pixels(1)),
        radius: const BorderRadius.circular(Unit.pixels(10)),
        backgroundColor: AppColors.white,
        raw: const <String, String>{
          'outline': 'none',
          'resize': 'none',
          'field-sizing': 'content',
          'caret-color': '#2B4BF2',
        },
      )
      .combine(AppTextStyles.bodyMd)
      .combine(const Styles(lineHeight: Unit.pixels(20))),
  css('.report-comment__input:focus').styles(
    border: Border.all(color: AppColors.primary, width: const Unit.pixels(1)),
    raw: const <String, String>{'box-shadow': 'inset 0 0 0 0.5px #2B4BF2'},
  ),
  css('.report-comment__input--error').styles(
    border: Border.all(color: AppColors.danger, width: const Unit.pixels(1)),
  ),
  css('.report-comment__input--error:focus').styles(
    border: Border.all(color: AppColors.danger, width: const Unit.pixels(1)),
    raw: const <String, String>{'box-shadow': 'inset 0 0 0 0.5px #E5484D'},
  ),
  css('.report-comment__input::placeholder').styles(opacity: 1, color: AppColors.faint),
  css('.report-comment__footer').styles(
    display: Display.flex,
    padding: const Padding.only(left: Unit.pixels(14), top: Unit.pixels(8), right: Unit.pixels(14)),
    alignItems: AlignItems.start,
    gap: const Gap.column(Unit.pixels(16)),
  ),
  css('.report-comment__error')
      .styles(
        minWidth: Unit.zero,
        flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
      )
      .combine(AppTextStyles.bodySm)
      .combine(const Styles(color: AppColors.danger)),
  css('.report-comment__counter')
      .styles(
        margin: const Margin.only(left: Unit.auto),
        flex: const Flex(shrink: 0),
      )
      .combine(AppTextStyles.monoCaption)
      .combine(const Styles(color: AppColors.faint)),
];
