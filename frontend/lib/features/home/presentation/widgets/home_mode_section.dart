import 'package:bloc_signals_jaspr/bloc_signals_jaspr.dart' hide Transition;
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

import 'package:skill_battles/app/router/app_navigation.dart';
import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/formatters/display_formatters.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/core/presentation/widgets/app_inline_error.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';
import 'package:skill_battles/core/presentation/widgets/app_tappable.dart';
import 'package:skill_battles/core/presentation/widgets/app_text_input.dart';
import 'package:skill_battles/core/utils/error/api_error_codes.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/error/failure_message.dart';
import 'package:skill_battles/core/utils/form_validators.dart';
import 'package:skill_battles/features/account/domain/entity/limits_entity.dart';
import 'package:skill_battles/features/catalog/domain/entity/discipline_entity.dart';
import 'package:skill_battles/features/home/presentation/bloc/home_bloc/home_bloc.dart';
import 'package:skill_battles/features/home/presentation/widgets/home_daily_limit_dialog.dart';
import 'package:skill_battles/features/private_duel/domain/entity/join_duel_params_entity.dart';

/// Ranked (with the shared Free daily limit), private duel (always
/// unlimited) and join by code, with the limit meter below.
final class HomeModeSection extends StatelessComponent {
  const HomeModeSection({required this.discipline, required this.limits, super.key});

  final DisciplineEntity? discipline;
  final LimitsEntity? limits;

  @override
  Component build(BuildContext context) {
    final LimitsEntity? limits = this.limits;
    return div(classes: 'home-mode-section', <Component>[
      div(classes: 'home-mode-section__tiles', <Component>[
        div(classes: 'home-mode-section__ranked', <Component>[
          _RankedTile(discipline: discipline, limits: limits),
        ]),
        div(classes: 'home-mode-section__tile', <Component>[_PrivateTile(discipline: discipline)]),
        const div(classes: 'home-mode-section__tile', <Component>[_CodeTile()]),
      ]),
      if (limits != null && !limits.entitlements.unlimitedRanked) _LimitMeter(limits: limits),
    ]);
  }
}

final class _RankedTile extends StatelessComponent {
  const _RankedTile({required this.discipline, required this.limits});

  final DisciplineEntity? discipline;
  final LimitsEntity? limits;

  @override
  Component build(BuildContext context) {
    final DisciplineEntity? discipline = this.discipline;
    final LimitsEntity? limits = this.limits;
    final bool limitReached = limits != null && !limits.canStartRanked;
    final bool enabled = discipline != null && discipline.contentAvailable;
    final String subtitle = enabled ? 'Opponent near your ${discipline.displayName} rating' : 'Not available right now';

    return AppTappable(
      radius: 14,
      semanticLabel: 'Find ranked match. $subtitle',
      classes: enabled ? 'home-ranked-tile home-ranked-tile--enabled' : 'home-ranked-tile',
      onTap: !enabled
          ? null
          : limitReached
          ? () => showHomeDailyLimitDialog(context, limits: limits, disciplineCode: discipline.code)
          : () => context.goRankedSearch(disciplineCode: discipline.code),
      child: div(classes: 'home-ranked-tile__content', <Component>[
        div(classes: 'home-mode-tile__texts', <Component>[
          const p(classes: 'home-ranked-tile__title', <Component>[Component.text('Find ranked match')]),
          p(classes: 'home-ranked-tile__subtitle', <Component>[Component.text(subtitle)]),
        ]),
        if (enabled) const AppSvgIcon(AppIcons.arrowRight, width: 28, height: 28),
      ]),
    );
  }
}

final class _PrivateTile extends StatelessComponent {
  const _PrivateTile({required this.discipline});

  final DisciplineEntity? discipline;

  @override
  Component build(BuildContext context) {
    final DisciplineEntity? discipline = this.discipline;
    final bool enabled = discipline != null && discipline.contentAvailable;
    return AppTappable(
      radius: 14,
      semanticLabel: 'Create private duel, unlimited, no rating change',
      classes: enabled ? 'home-private-tile home-private-tile--enabled' : 'home-private-tile',
      onTap: enabled ? () => context.goPrivateDuel(disciplineCode: discipline.code) : null,
      child: div(classes: 'home-mode-tile__texts', <Component>[
        const p(classes: 'home-private-tile__title', <Component>[Component.text('Create private duel')]),
        const p(classes: 'home-private-tile__subtitle', <Component>[Component.text('Unlimited · no rating change')]),
      ]),
    );
  }
}

/// Free daily ranked usage: one bar per match, then the count and reset.
final class _LimitMeter extends StatelessComponent {
  const _LimitMeter({required this.limits});

  final LimitsEntity limits;

  @override
  Component build(BuildContext context) {
    final int total = limits.freeRankedLimit;
    final int remaining = (limits.freeRankedRemaining ?? 0).clamp(0, total);
    return div(classes: 'home-limit-meter', <Component>[
      div(
        classes: 'home-limit-meter__bars',
        attributes: const <String, String>{'aria-hidden': 'true'},
        <Component>[
          for (int i = 0; i < total; i++)
            span(
              classes: 'home-limit-meter__bar',
              styles: Styles(backgroundColor: i < remaining ? AppColors.primary : AppColors.border),
              const <Component>[],
            ),
        ],
      ),
      p(classes: 'home-limit-meter__text', <Component>[
        span(classes: 'home-limit-meter__count', <Component>[Component.text('$remaining of $total')]),
        const span(<Component>[Component.text(' free ranked matches left today')]),
        span(classes: 'home-limit-meter__reset', <Component>[
          Component.text(' · resets ${DisplayFormatters.time(limits.resetsAt)} your time'),
        ]),
      ]),
    ]);
  }
}

final class _CodeTile extends StatefulComponent {
  const _CodeTile();

  @override
  State<_CodeTile> createState() => _CodeTileState();
}

final class _CodeTileState extends State<_CodeTile> {
  static const int _codeLength = FormValidators.duelCodeLength;
  static int _nextId = 0;

  static final List<TextInputFormatter> _formatters = <TextInputFormatter>[
    FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
    const _UpperCaseFormatter(),
    const LengthLimitingTextInputFormatter(_codeLength),
  ];

  late final String _inputId;
  late final TextEditingController _controller;
  late final GlobalNodeKey<web.HTMLInputElement> _inputKey;

  /// Client validation message; the tile has no room for it inside.
  late final ValueNotifier<String?> _localError;

  @override
  void initState() {
    super.initState();
    _inputId = 'home-code-input-${_nextId++}';
    _controller = TextEditingController();
    _inputKey = GlobalNodeKey<web.HTMLInputElement>();
    _localError = ValueNotifier<String?>(null);
  }

  @override
  void dispose() {
    _controller.dispose();
    _localError.dispose();
    super.dispose();
  }

  void _onInput(web.Event event) {
    final web.HTMLInputElement input = event.target! as web.HTMLInputElement;
    final String previous = _controller.text;
    String next = input.value;
    for (final TextInputFormatter formatter in _formatters) {
      next = formatter.formatEditUpdate(previous, next);
    }
    if (next != input.value) input.value = next;
    _controller.text = next;
    _localError.value = null;
    context.read<HomeBloc>().add(const HomeJoinCodeEdited());
  }

  void _onKeyDown(web.Event event) {
    final web.KeyboardEvent key = event as web.KeyboardEvent;
    if (key.key != 'Enter' || key.isComposing) return;
    event.preventDefault();
    _submit();
  }

  void _submit() {
    final String? error = FormValidators.duelCode(_controller.text);
    _localError.value = error;
    if (error != null) {
      _inputKey.currentNode?.focus();
      return;
    }
    context.read<HomeBloc>().add(HomeJoinDuelSubmitted(JoinDuelParamsEntity(code: _controller.text)));
  }

  static String _joinMessage(Failure failure) {
    if (failure.hasCode(ApiErrorCodes.duelNotFound)) {
      return 'No room with this code.';
    }
    if (failure.hasCode(ApiErrorCodes.duelExpired)) {
      return 'This code has expired.';
    }
    if (failure.hasCode(ApiErrorCodes.selfJoinNotAllowed)) {
      return "That's your own room — share the code with a friend.";
    }
    if (failure.hasCode(ApiErrorCodes.duelNotJoinable)) {
      return 'This room already has an opponent.';
    }
    if (failure.hasCode(ApiErrorCodes.activityConflict)) {
      return 'Finish or leave your current match first.';
    }
    return failure.userMessage;
  }

  @override
  Component build(BuildContext context) {
    return div(classes: 'home-code-tile', <Component>[
      // The box shows the input's focus (see the `:has` rule below).
      div(classes: 'home-code-tile__box', <Component>[
        // A click anywhere on the label part focuses the input.
        label(htmlFor: _inputId, classes: 'home-code-tile__field', <Component>[
          const span(classes: 'home-code-tile__label', <Component>[Component.text('Have a code?')]),
          input<String>(
            key: _inputKey,
            id: _inputId,
            type: InputType.text,
            value: _controller.text,
            classes: 'home-code-tile__input',
            attributes: <String, String>{
              'placeholder': 'K7Q2__',
              'autocomplete': 'off',
              'autocapitalize': 'characters',
              'autocorrect': 'off',
              'spellcheck': 'false',
              'enterkeyhint': TextInputAction.go.value,
              'maxlength': '$_codeLength',
            },
            events: <String, void Function(web.Event)>{'input': _onInput, 'keydown': _onKeyDown},
          ),
        ]),
        BlocSignalSelector<HomeBloc, HomeState, bool>(
          selector: (HomeState state) => state.joinStatus.isLoading,
          builder: (BuildContext context, bool isJoining) => AppButton(
            label: isJoining ? 'Joining…' : 'Join',
            variant: AppButtonVariant.dark,
            size: AppButtonSize.small,
            onPressed: isJoining ? null : _submit,
          ),
        ),
      ]),
      ValueListenableBuilder<String?>(
        listenable: _localError,
        builder: (BuildContext context, String? localError) => BlocSignalSelector<HomeBloc, HomeState, Failure?>(
          selector: (HomeState state) => state.joinFailure,
          builder: (BuildContext context, Failure? failure) {
            final String? message = localError ?? (failure == null ? null : _joinMessage(failure));
            return message == null ? const Component.empty() : AppInlineError(message);
          },
        ),
      ),
    ]);
  }
}

final class _UpperCaseFormatter extends TextInputFormatter {
  const _UpperCaseFormatter();

  @override
  String formatEditUpdate(String oldValue, String newValue) => newValue.toUpperCase();
}

@css
List<StyleRule> get homeModeSectionStyles => <StyleRule>[
  css('.home-mode-section').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    alignItems: AlignItems.start,
    gap: const Gap.row(Unit.pixels(16)),
  ),
  css('.home-mode-section__tiles').styles(
    display: Display.flex,
    width: const Unit.percent(100),
    alignItems: AlignItems.start,
    gap: const Gap.column(Unit.pixels(20)),
  ),
  css('.home-mode-section__ranked').styles(
    minWidth: Unit.zero,
    flex: const Flex(grow: 13, shrink: 1, basis: Unit.zero),
  ),
  css('.home-mode-section__tile').styles(
    minWidth: Unit.zero,
    flex: const Flex(grow: 10, shrink: 1, basis: Unit.zero),
  ),
  css('.home-mode-tile__texts').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    flexDirection: FlexDirection.column,
    justifyContent: JustifyContent.center,
    alignItems: AlignItems.start,
    gap: const Gap.row(Unit.pixels(4)),
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.home-ranked-tile').styles(
    display: Display.flex,
    height: const Unit.pixels(88),
    padding: const Padding.symmetric(horizontal: Unit.pixels(28)),
    radius: const BorderRadius.circular(Unit.pixels(14)),
    backgroundColor: AppColors.surface,
  ),
  css('.home-ranked-tile--enabled').styles(backgroundColor: AppColors.primary),
  css('.home-ranked-tile__content').styles(
    display: Display.flex,
    width: const Unit.percent(100),
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(12)),
  ),
  css('.home-ranked-tile__title')
      .styles(
        maxWidth: const Unit.percent(100),
        overflow: Overflow.hidden,
        textOverflow: TextOverflow.ellipsis,
        whiteSpace: WhiteSpace.noWrap,
      )
      .combine(AppTextStyles.titleLg)
      .combine(const Styles(color: AppColors.faint)),
  css('.home-ranked-tile--enabled .home-ranked-tile__title').styles(color: AppColors.white),
  css('.home-ranked-tile__subtitle')
      .styles(
        maxWidth: const Unit.percent(100),
        overflow: Overflow.hidden,
        textOverflow: TextOverflow.ellipsis,
        whiteSpace: WhiteSpace.noWrap,
      )
      .combine(AppTextStyles.bodySm)
      .combine(const Styles(color: AppColors.muted)),
  css('.home-ranked-tile--enabled .home-ranked-tile__subtitle').styles(color: AppColors.onPrimarySubtle),
  css('.home-private-tile').styles(
    display: Display.flex,
    height: const Unit.pixels(88),
    padding: const Padding.symmetric(horizontal: Unit.pixels(24)),
    border: Border.all(color: AppColors.border, width: const Unit.pixels(1.5)),
    radius: const BorderRadius.circular(Unit.pixels(14)),
  ),
  css('.home-private-tile--enabled').styles(
    border: Border.all(color: AppColors.ink, width: const Unit.pixels(1.5)),
  ),
  css('.home-private-tile__title')
      .styles(
        maxWidth: const Unit.percent(100),
        overflow: Overflow.hidden,
        textOverflow: TextOverflow.ellipsis,
        whiteSpace: WhiteSpace.noWrap,
      )
      .combine(AppTextStyles.titleMd)
      .combine(const Styles(color: AppColors.faint)),
  css('.home-private-tile--enabled .home-private-tile__title').styles(color: AppColors.ink),
  css('.home-private-tile__subtitle')
      .styles(
        maxWidth: const Unit.percent(100),
        overflow: Overflow.hidden,
        textOverflow: TextOverflow.ellipsis,
        whiteSpace: WhiteSpace.noWrap,
      )
      .combine(AppTextStyles.bodySm)
      .combine(const Styles(color: AppColors.muted)),
  css('.home-limit-meter').styles(
    display: Display.flex,
    maxWidth: const Unit.percent(100),
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(16)),
  ),
  css('.home-limit-meter__bars').styles(
    display: Display.flex,
    gap: const Gap.column(Unit.pixels(4)),
    flex: const Flex(shrink: 0),
  ),
  css('.home-limit-meter__bar').styles(
    display: Display.block,
    width: const Unit.pixels(20),
    height: const Unit.pixels(6),
    radius: const BorderRadius.circular(Unit.pixels(3)),
  ),
  css('.home-limit-meter__text').styles(minWidth: Unit.zero).combine(AppTextStyles.bodySm),
  css('.home-limit-meter__count').styles(fontWeight: FontWeight.w600),
  css('.home-limit-meter__reset').styles(color: AppColors.muted),
  css('.home-code-tile').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(8)),
  ),
  css('.home-code-tile__box').styles(
    display: Display.flex,
    height: const Unit.pixels(88),
    padding: const Padding.only(left: Unit.pixels(20), right: Unit.pixels(12)),
    border: Border.all(color: Colors.transparent, width: const Unit.pixels(1.5)),
    radius: const BorderRadius.circular(Unit.pixels(14)),
    transition: const Transition('border-color', duration: Duration(milliseconds: 120)),
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(12)),
    backgroundColor: AppColors.surface,
  ),
  css('.home-code-tile__box:has(.home-code-tile__input:focus)').styles(
    border: Border.all(color: AppColors.primary, width: const Unit.pixels(1.5)),
  ),
  css('.home-code-tile__field').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    cursor: Cursor.text,
    flexDirection: FlexDirection.column,
    justifyContent: JustifyContent.center,
    gap: const Gap.row(Unit.pixels(4)),
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
    alignSelf: AlignSelf.stretch,
  ),
  css('.home-code-tile__label')
      .combine(AppTextStyles.bodyXs)
      .combine(const Styles(color: AppColors.muted, fontWeight: FontWeight.w500)),
  css('.home-code-tile__input')
      .styles(
        width: const Unit.percent(100),
        minWidth: Unit.zero,
        padding: Padding.zero,
        backgroundColor: Colors.transparent,
        raw: const <String, String>{'border': 'none', 'outline': 'none', 'caret-color': '#0E0F12'},
      )
      .combine(AppTextStyles.monoSm)
      .combine(const Styles(letterSpacing: Unit.em(0.18))),
  css('.home-code-tile__input:focus-visible').styles(raw: const <String, String>{'outline': 'none'}),
  css('.home-code-tile__input::placeholder').styles(opacity: 1, color: AppColors.faint),
];
