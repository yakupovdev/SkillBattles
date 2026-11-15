import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/widgets/app_eyebrow.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';
import 'package:skill_battles/core/presentation/widgets/app_tappable.dart';

/// The modal shell of "19 Report question": white, radius 20, dialog shadow,
/// 32 px padding, an eyebrow and a title with a close button.
///
/// A `null` [onClose] hides the × but keeps its slot, and blocks dismissal by
/// Esc and the barrier (a request is in flight).
final class FriendsDialogShell extends StatelessWidget {
  const FriendsDialogShell({
    required this.eyebrow,
    required this.title,
    required this.onClose,
    required this.children,
    this.width = 480,
    super.key,
  });

  final String eyebrow;
  final String title;
  final VoidCallback? onClose;
  final List<Widget> children;
  final double width;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? close = onClose;
    return PopScope(
      canPop: close != null,
      child: Dialog(
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
            width: width,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
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
                            AppEyebrow(eyebrow),
                            Text(
                              title,
                              style: AppTextStyles.titleXlCompact.copyWith(
                                height: 32 / 28,
                                letterSpacing: -0.02 * 28,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (close == null)
                        const SizedBox.square(dimension: 48)
                      else
                        AppTappable(
                          onTap: close,
                          borderRadius: BorderRadius.circular(24),
                          semanticLabel: 'Close',
                          child: const SizedBox.square(
                            dimension: 48,
                            child: Center(
                              child: AppSvgIcon(
                                AppIcons.close,
                                width: 20,
                                height: 20,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
