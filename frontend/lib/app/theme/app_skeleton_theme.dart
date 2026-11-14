import 'package:material_ui/material_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:skill_battles/app/theme/app_colors.dart';

/// The only place the skeleton look is configured: a shimmer, or a still
/// fill when the platform asks for reduced motion.
final class AppSkeletonTheme extends StatelessWidget {
  const AppSkeletonTheme({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bool still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return SkeletonizerConfig(
      data: SkeletonizerConfigData(
        effectResolver: (Brightness _) => still
            ? const SolidColorEffect(color: AppColors.skeletonLight)
            : const ShimmerEffect(
                baseColor: AppColors.skeletonLight,
                highlightColor: AppColors.skeletonHighlight,
              ),
      ),
      child: child,
    );
  }
}
