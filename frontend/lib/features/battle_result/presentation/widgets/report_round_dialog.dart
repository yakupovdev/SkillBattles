import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/features/battle_result/domain/entity/report_params_entity.dart';
import 'package:skill_battles/features/battle_result/domain/entity/report_reason.dart';

/// Asks for a report reason and comment; `null` when dismissed. Reporting
/// never reveals the correct answer and never changes the rating.
Future<ReportParamsEntity?> showReportRoundDialog(
  BuildContext context, {
  required String battleId,
  required String roundId,
}) => showDialog<ReportParamsEntity>(
  context: context,
  builder: (BuildContext context) =>
      ReportRoundDialog(battleId: battleId, roundId: roundId),
);

final class ReportRoundDialog extends StatefulWidget {
  const ReportRoundDialog({
    required this.battleId,
    required this.roundId,
    super.key,
  });

  final String battleId;
  final String roundId;

  @override
  State<ReportRoundDialog> createState() => _ReportRoundDialogState();
}

final class _ReportRoundDialogState extends State<ReportRoundDialog> {
  late final GlobalKey<FormState> _formKey;
  late final TextEditingController _comment;
  late ReportReason _reason;

  static const Map<ReportReason, String> _labels = <ReportReason, String>{
    ReportReason.incorrectAnswer: 'The answer key looks wrong',
    ReportReason.unclearQuestion: 'The question is unclear',
    ReportReason.typo: 'Typo or formatting',
    ReportReason.other: 'Something else',
  };

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
    return Dialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteractionIfError,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: <Widget>[
                const Text('Report a problem', style: AppTextStyles.titleLg),
                Text(
                  'We review every report. It does not change your score.',
                  style: AppTextStyles.bodyMd.copyWith(color: AppColors.muted),
                ),
                RadioGroup<ReportReason>(
                  groupValue: _reason,
                  onChanged: (ReportReason? value) {
                    if (value != null) setState(() => _reason = value);
                  },
                  child: Column(
                    children: <Widget>[
                      for (final ReportReason reason in ReportReason.values)
                        RadioListTile<ReportReason>(
                          value: reason,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text(
                            _labels[reason]!,
                            style: AppTextStyles.bodyMd,
                          ),
                        ),
                    ],
                  ),
                ),
                TextFormField(
                  controller: _comment,
                  maxLines: 3,
                  maxLength: ReportParamsEntity.maxCommentLength,
                  decoration: InputDecoration(
                    hintText: _reason == ReportReason.other
                        ? 'Describe the problem (required)'
                        : 'Comment (optional)',
                  ),
                  validator: (String? value) =>
                      _reason == ReportReason.other &&
                          (value?.trim() ?? '').isEmpty
                      ? 'Describe the problem'
                      : null,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  spacing: 12,
                  children: <Widget>[
                    AppButton(
                      label: 'Cancel',
                      variant: AppButtonVariant.outline,
                      size: AppButtonSize.small,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    AppButton(
                      label: 'Send report',
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
    );
  }
}
