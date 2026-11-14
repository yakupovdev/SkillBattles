import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';

/// A mono value over a small muted label.
final class AppStat extends StatelessWidget {
  const AppStat({
    required this.value,
    required this.label,
    this.valueColor = AppColors.ink,
    this.valueStyle = AppTextStyles.monoSm,
    super.key,
  });

  final String value;
  final String label;
  final Color valueColor;
  final TextStyle valueStyle;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 2,
        children: <Widget>[
          Text(value, style: valueStyle.copyWith(color: valueColor)),
          Text(
            label,
            style: AppTextStyles.bodyXs.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
