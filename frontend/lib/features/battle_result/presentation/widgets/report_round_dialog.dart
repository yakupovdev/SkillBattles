import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/core/presentation/widgets/app_eyebrow.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';
import 'package:skill_battles/core/presentation/widgets/app_tappable.dart';
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
}) => showDialog<ReportParamsEntity>(
  context: context,
  barrierColor: AppColors.scrim,
  builder: (BuildContext dialogContext) => ReportRoundDialog(
    battleId: battleId,
    roundId: roundId,
    eyebrow: eyebrow,
    prompt: prompt,
  ),
);

final class ReportRoundDialog extends StatefulWidget {
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
  late final GlobalKey<FormState> _formKey;
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
    _formKey = GlobalKey<FormState>();
    _comment = TextEditingController();
    _reason = ReportReason.incorrectAnswer;
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final String comment = _comment.text.trim();
    Navigator.of(context).pop(
      ReportParamsEntity(
        battleId: widget.battleId,
        roundId: widget.roundId,
        reason: _reason,
        comment: comment.isEmpty ? null : comment,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String prompt = widget.prompt.length > _promptPreviewLength
        ? '${widget.prompt.substring(0, _promptPreviewLength).trimRight()}…'
        : widget.prompt;
    final TextStyle muted = AppTextStyles.bodyMd.copyWith(
      color: AppColors.muted,
      height: 20 / 14,
    );
    final bool commentRequired = _reason == ReportReason.other;
    return Dialog(
      backgroundColor: AppColors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: AppColors.dialogShadow,
              offset: Offset(0, 24),
              blurRadius: 64,
            ),
          ],
        ),
        child: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteractionIfError,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 22,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 8,
                          children: <Widget>[
                            AppEyebrow(widget.eyebrow),
                            Text(
                              'Report this question',
                              style: AppTextStyles.titleXlCompact.copyWith(
                                height: 32 / 28,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppTappable(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(6),
                        semanticLabel: 'Close',
                        child: const AppSvgIcon(
                          AppIcons.close,
                          width: 20,
                          height: 20,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '"$prompt" — our content team reviews every report. It '
                    "won't change ratings or reveal the answer.",
                    style: muted,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 8,
                    children: <Widget>[
                      for (final ReportReason reason in ReportReason.values)
                        _ReasonTile(
                          label: _labels[reason]!,
                          note: reason == ReportReason.other
                              ? ' (comment required)'
                              : null,
                          isSelected: reason == _reason,
                          onTap: () => setState(() => _reason = reason),
                        ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 6,
                    children: <Widget>[
                      Text.rich(
                        TextSpan(
                          children: <InlineSpan>[
                            const TextSpan(text: 'Comment '),
                            TextSpan(
                              text: commentRequired
                                  ? '· required'
                                  : '· optional',
                              style: AppTextStyles.bodySm.copyWith(
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                        style: AppTextStyles.bodySm.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      _CommentField(
                        controller: _comment,
                        isRequired: commentRequired,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    spacing: 10,
                    children: <Widget>[
                      SizedBox(
                        height: 46,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: Center(
                            widthFactor: 1,
                            child: AppTextLink(
                              label: 'Cancel',
                              style: AppTextStyles.bodyMd.copyWith(
                                color: AppColors.muted,
                                fontWeight: FontWeight.w500,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                        ),
                      ),
                      AppButton(
                        label: 'Send report',
                        variant: AppButtonVariant.dark,
                        size: AppButtonSize.small,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A 48 px radio row: blue outline and filled ring when selected.
final class _ReasonTile extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final String? note = this.note;
    return AppTappable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      isSelected: isSelected,
      semanticLabel: '$label${note ?? ''}',
      child: Container(
        height: 48,
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 16 : 17),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySurface : AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          spacing: 12,
          children: <Widget>[
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.borderStrong,
                  width: isSelected ? 5 : 1.5,
                ),
              ),
            ),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: <InlineSpan>[
                    TextSpan(text: label),
                    if (note != null)
                      TextSpan(
                        text: note,
                        style: AppTextStyles.bodyLg.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                  ],
                ),
                style: AppTextStyles.bodyLg.copyWith(
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The comment box with a "48 / 1000" counter inside its bottom edge.
final class _CommentField extends StatelessWidget {
  const _CommentField({required this.controller, required this.isRequired});

  final TextEditingController controller;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final OutlineInputBorder border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.border),
    );
    return TextFormField(
      controller: controller,
      minLines: 2,
      maxLines: 4,
      maxLength: ReportParamsEntity.maxCommentLength,
      style: AppTextStyles.bodyMd.copyWith(height: 20 / 14),
      buildCounter:
          (
            BuildContext context, {
            required int currentLength,
            required bool isFocused,
            required int? maxLength,
          }) => Text(
            '$currentLength / $maxLength',
            style: AppTextStyles.monoCaption.copyWith(color: AppColors.faint),
          ),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        hintText: isRequired ? 'Describe the problem' : null,
        hintStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.faint),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
      ),
      validator: (String? value) => isRequired && (value?.trim() ?? '').isEmpty
          ? 'Describe the problem'
          : null,
    );
  }
}
