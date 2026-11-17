import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/app/theme/app_shadows.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/overlay/app_overlay.dart';
import 'package:skill_battles/core/presentation/skeleton/skeletonizer.dart';
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
/// [maxHeight], and never stretched. A click opens it full size, where a
/// click toggles a 2× zoom. The background stays white so black chart labels
/// stay readable.
///
/// A failed load shows an error with Retry, which requests the same URL
/// again. Nothing here touches the match: the prompt and the options stay
/// usable whatever happens to the image.
final class QuestionIllustration extends StatefulComponent {
  const QuestionIllustration({
    required this.imageUrl,
    this.maxHeight = 420,
    super.key,
  });

  final String imageUrl;

  /// Upper bound of the image height on the page; taller charts are scaled
  /// down to it (full size is one click away).
  final double maxHeight;

  static const String semanticLabel = 'Question illustration';
  static const String errorMessage = "Couldn't load the illustration.";
  static const String retryLabel = 'Retry';

  @override
  State<QuestionIllustration> createState() => _QuestionIllustrationState();
}

enum _LoadStatus { loading, loaded, failed }

final class _QuestionIllustrationState extends State<QuestionIllustration> {
  late String _url;
  late int _attempt;
  late _LoadStatus _status;

  /// Context of the open full-size dialog, `null` when it is closed.
  BuildContext? _fullSize;

  @override
  void initState() {
    super.initState();
    _url = resolveMediaUrl(component.imageUrl);
    _attempt = 0;
    _status = _LoadStatus.loading;
  }

  @override
  void didUpdateComponent(QuestionIllustration oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.imageUrl != component.imageUrl) {
      _closeFullSize();
      _url = resolveMediaUrl(component.imageUrl);
      _attempt = 0;
      _status = _LoadStatus.loading;
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
    // Same URL, no cache-busting query: a new element requests it again.
    setState(() {
      _attempt++;
      _status = _LoadStatus.loading;
    });
  }

  void _setStatus(_LoadStatus status) {
    if (mounted && _status != status) setState(() => _status = status);
  }

  void _openFullSize() {
    final Future<void> closed = showAppDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        _fullSize = dialogContext;
        return _FullSizeDialog(url: _url);
      },
    );
    unawaited(closed.whenComplete(() => _fullSize = null));
  }

  /// Removes the full-size dialog if it is still open. Runs after the
  /// current build, because it is called while the tree is being built or
  /// torn down.
  void _closeFullSize() {
    final BuildContext? dialog = _fullSize;
    _fullSize = null;
    if (dialog == null) return;
    scheduleMicrotask(() => closeAppDialog<void>(dialog));
  }

  @override
  Component build(BuildContext context) {
    // Never load while skeletonized; the skeleton data has no illustration.
    if (Skeletonizer.isEnabled(context)) {
      return Skeleton.leaf(
        child: const _Frame(child: _Placeholder(child: Component.empty())),
      );
    }
    final _LoadStatus status = _status;
    return _Frame(
      label: QuestionIllustration.semanticLabel,
      child: Component.fragment(<Component>[
        if (status == _LoadStatus.loading) const _Placeholder(child: _Loading()),
        if (status == _LoadStatus.failed) _Placeholder(child: _LoadError(onRetry: _retry)),
        if (status != _LoadStatus.failed)
          AppTappable(
            key: ValueKey<int>(_attempt),
            onTap: status == _LoadStatus.loaded ? _openFullSize : null,
            radius: 4,
            semanticLabel: QuestionIllustration.semanticLabel,
            semanticValue: 'Open full size',
            classes: status == _LoadStatus.loaded
                ? 'question-illustration__image'
                : 'question-illustration__image question-illustration__image--pending',
            child: img(
              src: _url,
              alt: '',
              styles: Styles(maxHeight: Unit.pixels(component.maxHeight)),
              attributes: const <String, String>{'crossorigin': 'anonymous', 'decoding': 'async'},
              events: <String, void Function(web.Event)>{
                'load': (web.Event _) => _setStatus(_LoadStatus.loaded),
                'error': (web.Event _) => _setStatus(_LoadStatus.failed),
              },
            ),
          ),
      ]),
    );
  }
}

/// White card around the image, also in the loading and error states.
final class _Frame extends StatelessComponent {
  const _Frame({required this.child, this.label});

  final Component child;
  final String? label;

  @override
  Component build(BuildContext context) {
    final String? name = label;
    return div(
      classes: 'question-illustration',
      attributes: name == null ? null : <String, String>{'role': 'figure', 'aria-label': name},
      <Component>[child],
    );
  }
}

/// Fixed-height box for the states without a decoded image.
final class _Placeholder extends StatelessComponent {
  const _Placeholder({required this.child});

  final Component child;

  @override
  Component build(BuildContext context) {
    return div(classes: 'question-illustration__placeholder', <Component>[child]);
  }
}

final class _Loading extends StatelessComponent {
  const _Loading();

  @override
  Component build(BuildContext context) {
    return const span(
      classes: 'question-illustration__spinner',
      attributes: <String, String>{'role': 'progressbar', 'aria-label': 'Loading'},
      <Component>[],
    );
  }
}

final class _LoadError extends StatelessComponent {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Component build(BuildContext context) {
    return div(
      classes: 'question-illustration__error',
      attributes: const <String, String>{'role': 'alert'},
      <Component>[
        const p(
          classes: 'question-illustration__error-text',
          <Component>[Component.text(QuestionIllustration.errorMessage)],
        ),
        AppTextLink(
          label: QuestionIllustration.retryLabel,
          style: AppTextStyles.bodySm.combine(const Styles(color: AppColors.primary, fontWeight: FontWeight.w600)),
          onPressed: onRetry,
        ),
      ],
    );
  }
}

/// The illustration enlarged to the dialog width; a click on it toggles a
/// 2× zoom, the box scrolls in both directions.
final class _FullSizeDialog extends StatefulComponent {
  const _FullSizeDialog({required this.url});

  final String url;

  @override
  State<_FullSizeDialog> createState() => _FullSizeDialogState();
}

final class _FullSizeDialogState extends State<_FullSizeDialog> {
  late bool _isZoomed;

  @override
  void initState() {
    super.initState();
    _isZoomed = false;
  }

  @override
  Component build(BuildContext context) {
    return div(classes: 'question-illustration__dialog', <Component>[
      AppTappable(
        onTap: () => closeAppDialog<void>(context),
        radius: 8,
        semanticLabel: 'Close',
        classes: 'question-illustration__close',
        child: const AppSvgIcon(AppIcons.close, width: 20, height: 20, color: AppColors.muted),
      ),
      div(classes: 'question-illustration__zoom', <Component>[
        // Already in the browser cache: no second request.
        img(
          src: component.url,
          alt: QuestionIllustration.semanticLabel,
          classes: _isZoomed
              ? 'question-illustration__full question-illustration__full--zoomed'
              : 'question-illustration__full',
          attributes: const <String, String>{'crossorigin': 'anonymous'},
          events: <String, void Function(web.Event)>{'click': (web.Event _) => setState(() => _isZoomed = !_isZoomed)},
        ),
      ]),
    ]);
  }
}

@css
List<StyleRule> get questionIllustrationStyles => <StyleRule>[
  css('.question-illustration').styles(
    display: Display.flex,
    width: Unit.fitContent,
    maxWidth: const Unit.percent(100),
    padding: const Padding.all(Unit.pixels(12)),
    border: Border.all(color: AppColors.border, width: const Unit.pixels(1)),
    radius: const BorderRadius.circular(Unit.pixels(12)),
    flexDirection: FlexDirection.column,
    alignSelf: AlignSelf.start,
    backgroundColor: AppColors.white,
  ),
  css('.question-illustration__placeholder').styles(
    display: Display.flex,
    width: const Unit.pixels(320),
    height: const Unit.pixels(160),
    maxWidth: const Unit.percent(100),
    justifyContent: JustifyContent.center,
    alignItems: AlignItems.center,
  ),
  css('.question-illustration__image').styles(display: Display.block, maxWidth: const Unit.percent(100)),
  css('.question-illustration__image--pending').styles(display: Display.none),
  css('.question-illustration__image img').styles(
    display: Display.block,
    width: Unit.auto,
    height: Unit.auto,
    maxWidth: const Unit.percent(100),
    raw: const <String, String>{'object-fit': 'contain'},
  ),
  css('.question-illustration__spinner').styles(
    display: Display.inlineBlock,
    width: const Unit.pixels(24),
    height: const Unit.pixels(24),
    border: Border.all(color: AppColors.divider, width: const Unit.pixels(2)),
    radius: const BorderRadius.circular(Unit.percent(50)),
    raw: const <String, String>{
      'border-top-color': '#A0A3AB',
      'animation': 'app-spin 0.8s linear infinite',
    },
  ),
  css('.question-illustration__error').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    alignItems: AlignItems.center,
    gap: const Gap.row(Unit.pixels(8)),
  ),
  css('.question-illustration__error-text')
      .combine(AppTextStyles.bodySm)
      .combine(const Styles(color: AppColors.danger, textAlign: TextAlign.center, lineHeight: Unit.pixels(18))),
  css('.question-illustration__dialog').styles(
    display: Display.flex,
    width: const Unit.expression('min(960px, calc(100vw - 48px))'),
    maxHeight: const Unit.expression('calc(100vh - 48px)'),
    padding: const Padding.all(Unit.pixels(16)),
    radius: const BorderRadius.circular(Unit.pixels(16)),
    shadow: AppShadows.dialog,
    flexDirection: FlexDirection.column,
    alignItems: AlignItems.end,
    gap: const Gap.row(Unit.pixels(8)),
    backgroundColor: AppColors.white,
  ),
  css('.question-illustration__close').styles(padding: const Padding.all(Unit.pixels(4))),
  css('.question-illustration__zoom').styles(
    width: const Unit.percent(100),
    minHeight: Unit.zero,
    overflow: Overflow.auto,
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.auto),
  ),
  css('.question-illustration__full').styles(
    display: Display.block,
    width: const Unit.percent(100),
    height: Unit.auto,
    cursor: Cursor.zoomIn,
  ),
  css('.question-illustration__full--zoomed').styles(
    width: const Unit.percent(200),
    cursor: Cursor.zoomOut,
  ),
];
