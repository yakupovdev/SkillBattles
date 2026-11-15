import 'package:material_ui/material_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';
import 'package:skill_battles/core/presentation/widgets/app_tappable.dart';
import 'package:skill_battles/core/presentation/widgets/app_text_link.dart';
import 'package:skill_battles/core/utils/network/media_url.dart';

/// The chart or diagram of a question, shown above its prompt.
///
/// [imageUrl] is the origin-relative URL the server returned; it is resolved
/// against the public media origin (`resolveMediaUrl`) and loaded with a
/// plain GET, without credentials.
///
/// The image keeps its aspect ratio and is never cropped: it is shown at its
/// natural size, scaled down (contain) to the available width and
/// [maxHeight], and never stretched. A tap opens it full size with zoom. The
/// background stays white so black chart labels stay readable.
///
/// A failed load shows an error with Retry, which requests the same URL
/// again. Nothing here touches the match: the prompt and the options stay
/// usable whatever happens to the image.
final class QuestionIllustration extends StatefulWidget {
  const QuestionIllustration({
    required this.imageUrl,
    this.maxHeight = 420,
    super.key,
  });

  final String imageUrl;

  /// Upper bound of the image height on the page; taller charts are scaled
  /// down to it (full size is one tap away).
  final double maxHeight;

  static const String semanticLabel = 'Question illustration';
  static const String errorMessage = "Couldn't load the illustration.";
  static const String retryLabel = 'Retry';

  @override
  State<QuestionIllustration> createState() => _QuestionIllustrationState();
}

final class _QuestionIllustrationState extends State<QuestionIllustration> {
  late String _url;
  late int _attempt;
  late Route<void>? _fullSize;
  late NavigatorState? _navigator;

  @override
  void initState() {
    super.initState();
    _url = resolveMediaUrl(widget.imageUrl);
    _attempt = 0;
    _fullSize = null;
    _navigator = null;
  }

  @override
  void didUpdateWidget(QuestionIllustration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _closeFullSize();
      _url = resolveMediaUrl(widget.imageUrl);
      _attempt = 0;
    }
  }

  @override
  void dispose() {
    // A new round replaces the question: its chart must not stay open over
    // the next one while the clock runs.
    _closeFullSize();
    super.dispose();
  }

  void _retry() {
    // Same URL, no cache-busting query: drop the failed entry and resolve
    // the image again under a new key.
    NetworkImage(_url).evict();
    setState(() => _attempt++);
  }

  void _openFullSize() {
    final NavigatorState navigator = Navigator.of(context, rootNavigator: true);
    final DialogRoute<void> route = DialogRoute<void>(
      context: context,
      themes: InheritedTheme.capture(from: context, to: navigator.context),
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      builder: (BuildContext context) => _FullSizeDialog(url: _url),
    );
    _fullSize = route;
    _navigator = navigator;
    route.popped.whenComplete(() {
      if (identical(_fullSize, route)) _fullSize = null;
    });
    navigator.push(route);
  }

  /// Removes the full-size dialog if it is still open. Runs after the frame,
  /// because it is called while the tree is being built or torn down.
  void _closeFullSize() {
    final Route<void>? route = _fullSize;
    final NavigatorState? navigator = _navigator;
    _fullSize = null;
    if (route == null || navigator == null) return;
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (route.isActive && navigator.mounted) navigator.removeRoute(route);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Never load while skeletonized; the skeleton data has no illustration.
    if (Skeletonizer.maybeOf(context)?.enabled ?? false) {
      return const Skeleton.leaf(
        child: _Frame(child: SizedBox(height: _Placeholder.height)),
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        container: true,
        image: true,
        label: QuestionIllustration.semanticLabel,
        child: _Frame(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: widget.maxHeight),
            child: Image.network(
              _url,
              key: ValueKey<int>(_attempt),
              fit: BoxFit.contain,
              excludeFromSemantics: true,
              frameBuilder:
                  (
                    BuildContext context,
                    Widget child,
                    int? frame,
                    bool wasSynchronouslyLoaded,
                  ) {
                    if (frame == null && !wasSynchronouslyLoaded) {
                      return const _Placeholder(child: _Loading());
                    }
                    return AppTappable(
                      onTap: _openFullSize,
                      borderRadius: BorderRadius.circular(4),
                      semanticValue: 'Open full size',
                      child: child,
                    );
                  },
              errorBuilder: (
                BuildContext context,
                Object error,
                StackTrace? stack,
              ) => _Placeholder(child: _LoadError(onRetry: _retry)),
            ),
          ),
        ),
      ),
    );
  }
}

/// White card around the image, also in the loading and error states.
final class _Frame extends StatelessWidget {
  const _Frame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(padding: const EdgeInsets.all(12), child: child),
    );
  }
}

/// Fixed-height box for the states without a decoded image.
final class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.child});

  static const double height = 160;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Center(child: child),
    );
  }
}

final class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      value: 'Loading',
      child: const SizedBox.square(
        dimension: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.faint,
        ),
      ),
    );
  }
}

final class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: <Widget>[
          Text(
            QuestionIllustration.errorMessage,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.danger,
              height: 18 / 13,
            ),
          ),
          AppTextLink(
            label: QuestionIllustration.retryLabel,
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

/// The illustration enlarged to the dialog width, with pinch / scroll zoom.
final class _FullSizeDialog extends StatelessWidget {
  const _FullSizeDialog({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: 8,
            children: <Widget>[
              AppTappable(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(8),
                semanticLabel: 'Close',
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: AppSvgIcon(
                    AppIcons.close,
                    width: 20,
                    height: 20,
                    color: AppColors.muted,
                  ),
                ),
              ),
              Flexible(
                child: InteractiveViewer(
                  maxScale: 4,
                  child: Semantics(
                    image: true,
                    label: QuestionIllustration.semanticLabel,
                    // Already in the image cache: no second request.
                    // Fills the dialog width, so a small diagram is shown
                    // larger than on the page.
                    child: Image.network(
                      url,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      excludeFromSemantics: true,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
