import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/app/theme/app_shadows.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/widgets/app_countdown_text.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';
import 'package:skill_battles/features/battle/domain/entity/sticker_id.dart';
import 'package:skill_battles/features/battle/presentation/widgets/mute_opponent_toggle.dart';
import 'package:skill_battles/features/battle/presentation/widgets/sticker_caret.dart';
import 'package:skill_battles/features/battle/presentation/widgets/sticker_cell.dart';
import 'package:skill_battles/features/battle/presentation/widgets/sticker_labels.dart';

/// The 200 px popover with the 3 x 3 sticker grid (Paper: "32 Battle
/// stickers — Component sheet", states A-D).
///
/// While [cooldownUntil] is set the grid is dimmed and not tappable and the
/// footer counts down. Esc calls [onClose]; focus starts on the first cell
/// (or on the panel when the cells are off). Tab and Shift+Tab cycle inside
/// the picker; the arrow keys move between cells and stop at the grid's
/// edges.
final class StickerPicker extends StatefulComponent {
  const StickerPicker({
    required this.opponentNickname,
    required this.isOpponentHidden,
    required this.cooldownUntil,
    required this.caretCenter,
    required this.onSelected,
    required this.onToggleOpponentHidden,
    required this.onClose,
    super.key,
  });

  static const double width = 200;

  final String opponentNickname;
  final bool isOpponentHidden;
  final DateTime? cooldownUntil;

  /// Where the caret points, in px from the picker's left; clamped to
  /// 16-168.
  final double caretCenter;
  final ValueChanged<StickerId> onSelected;
  final VoidCallback onToggleOpponentHidden;
  final VoidCallback onClose;

  /// Grid order, row by row.
  static const List<List<StickerId>> rows = <List<StickerId>>[
    <StickerId>[StickerId.gg, StickerId.fire, StickerId.ez],
    <StickerId>[StickerId.lol, StickerId.tooSlow, StickerId.facepalm],
    <StickerId>[StickerId.hmm, StickerId.waitWhat, StickerId.crying],
  ];

  @override
  State<StickerPicker> createState() => _StickerPickerState();
}

final class _StickerPickerState extends State<StickerPicker> {
  late GlobalNodeKey<web.HTMLElement> _panelKey;
  late GlobalNodeKey<web.HTMLElement> _firstCellKey;
  late ValueNotifier<StickerId?> _highlighted;
  late ValueNotifier<StickerId?> _pressed;

  bool get _isCoolingDown => component.cooldownUntil != null;

  @override
  void initState() {
    super.initState();
    _panelKey = GlobalNodeKey<web.HTMLElement>(debugLabel: 'StickerPicker');
    _firstCellKey = GlobalNodeKey<web.HTMLElement>(debugLabel: 'StickerPickerFirstCell');
    _highlighted = ValueNotifier<StickerId?>(null);
    _pressed = ValueNotifier<StickerId?>(null);
    context.binding.addPostFrameCallback(() {
      if (!mounted) return;
      (_isCoolingDown ? _panelKey : _firstCellKey).currentNode?.focus();
    });
  }

  @override
  void dispose() {
    _highlighted.dispose();
    _pressed.dispose();
    super.dispose();
  }

  void _onKeyDown(web.Event event) {
    final web.KeyboardEvent key = event as web.KeyboardEvent;
    if (key.key == 'Escape') {
      key
        ..preventDefault()
        ..stopPropagation();
      component.onClose();
    } else if (key.key == 'Tab') {
      _cycleFocus(key);
    }
  }

  /// Keeps Tab inside the picker (a closed loop, like the Flutter focus
  /// scope); the panel itself is skipped.
  void _cycleFocus(web.KeyboardEvent event) {
    final web.HTMLElement? panel = _panelKey.currentNode;
    if (panel == null) return;
    final web.NodeList nodes = panel.querySelectorAll('[role="button"][tabindex="0"]');
    if (nodes.length == 0) {
      event.preventDefault();
      return;
    }
    final web.HTMLElement first = nodes.item(0)! as web.HTMLElement;
    final web.HTMLElement last = nodes.item(nodes.length - 1)! as web.HTMLElement;
    final web.Element? active = web.document.activeElement;
    if (event.shiftKey) {
      if (active == first || active == panel) {
        event.preventDefault();
        last.focus();
      }
    } else if (active == last || active == panel) {
      event.preventDefault();
      first.focus();
    }
  }

  void _setNotifier(ValueNotifier<StickerId?> notifier, StickerId id, {required bool isOn}) {
    if (isOn) {
      notifier.value = id;
    } else if (notifier.value == id) {
      notifier.value = null;
    }
  }

  @override
  Component build(BuildContext context) {
    final double caretLeft = component.caretCenter.clamp(16, 168) - 8;
    final bool isCoolingDown = _isCoolingDown;
    return div(
      key: _panelKey,
      classes: 'sticker-picker',
      attributes: const <String, String>{'role': 'dialog', 'aria-label': 'Stickers', 'tabindex': '-1'},
      events: <String, void Function(web.Event)>{'keydown': _onKeyDown},
      <Component>[
        div(classes: 'sticker-picker__box', <Component>[
          _PickerHeader(
            opponentNickname: component.opponentNickname,
            isOpponentHidden: component.isOpponentHidden,
            onToggleOpponentHidden: component.onToggleOpponentHidden,
          ),
          _GridKeyboard(
            enabled: !isCoolingDown,
            child: Component.fragment(<Component>[
              for (final List<StickerId> row in StickerPicker.rows)
                div(classes: 'sticker-picker__row', <Component>[
                  for (final StickerId id in row)
                    StickerCell(
                      key: ValueKey<StickerId>(id),
                      stickerId: id,
                      nodeKey: id == StickerId.gg ? _firstCellKey : null,
                      onSelected: isCoolingDown ? null : () => component.onSelected(id),
                      onHighlightChanged: (bool isOn) => _setNotifier(_highlighted, id, isOn: isOn),
                      onPressedChanged: (bool isOn) => _setNotifier(_pressed, id, isOn: isOn),
                    ),
                ]),
            ]),
          ),
          _PickerFooter(cooldownUntil: component.cooldownUntil, highlighted: _highlighted, pressed: _pressed),
        ]),
        StickerCaret(fill: AppColors.white, stroke: AppColors.border, left: caretLeft),
      ],
    );
  }
}

final class _PickerHeader extends StatelessComponent {
  const _PickerHeader({
    required this.opponentNickname,
    required this.isOpponentHidden,
    required this.onToggleOpponentHidden,
  });

  final String opponentNickname;
  final bool isOpponentHidden;
  final VoidCallback onToggleOpponentHidden;

  @override
  Component build(BuildContext context) {
    return div(classes: 'sticker-picker__header', <Component>[
      const span(classes: 'sticker-picker__title', <Component>[Component.text('STICKERS')]),
      MuteOpponentToggle(
        isHidden: isOpponentHidden,
        opponentNickname: opponentNickname,
        onTap: onToggleOpponentHidden,
      ),
    ]);
  }
}

final class _PickerFooter extends StatelessComponent {
  const _PickerFooter({required this.cooldownUntil, required this.highlighted, required this.pressed});

  final DateTime? cooldownUntil;
  final ValueListenable<StickerId?> highlighted;
  final ValueListenable<StickerId?> pressed;

  @override
  Component build(BuildContext context) {
    final DateTime? until = cooldownUntil;
    return div(classes: 'sticker-picker__footer', <Component>[
      if (until != null)
        div(classes: 'sticker-picker__cooldown', <Component>[
          const AppSvgIcon(AppIcons.clock, width: 14, height: 14, color: AppColors.primary),
          // Paper leaves exactly 144 px for the 20 mono glyphs; real glyph
          // metrics can be a few px wider, so the line is cut instead of
          // overflowing the 200 px picker.
          span(classes: 'sticker-picker__cooldown-text', <Component>[
            AppCountdownText(
              target: until,
              prefix: 'Next sticker in ',
              style: AppTextStyles.outcome.combine(const Styles(color: AppColors.primary)),
            ),
          ]),
        ])
      else
        ListenableBuilder(
          listenable: Listenable.merge(<Listenable>[highlighted, pressed]),
          builder: (BuildContext context) => _FooterText(highlighted: highlighted.value, pressed: pressed.value),
        ),
    ]);
  }
}

final class _FooterText extends StatelessComponent {
  const _FooterText({required this.highlighted, required this.pressed});

  final StickerId? highlighted;
  final StickerId? pressed;

  @override
  Component build(BuildContext context) {
    final StickerId? sending = pressed;
    final StickerId? shown = highlighted;
    return p(classes: 'sticker-picker__footer-text', <Component>[
      if (sending != null)
        span(classes: 'sticker-picker__footer-sending', <Component>[Component.text('Sending ${sending.label}…')])
      else if (shown != null) ...<Component>[
        span(classes: 'sticker-picker__footer-name', <Component>[Component.text(shown.label)]),
        span(<Component>[Component.text(' · ${shown.category.label}')]),
      ] else
        const span(<Component>[Component.text('Tap a sticker to send')]),
    ]);
  }
}

/// Arrow keys move focus inside the 3 x 3 grid and stop at its edges (they
/// never scroll the page). While [enabled] is false the cells are not
/// focusable (the cells set that themselves) and the arrows do nothing.
final class _GridKeyboard extends StatelessComponent {
  const _GridKeyboard({required this.enabled, required this.child});

  final bool enabled;
  final Component child;

  static const int _columns = 3;

  static void _onKeyDown(web.Event event) {
    final web.KeyboardEvent key = event as web.KeyboardEvent;
    final (int dRow, int dColumn) = switch (key.key) {
      'ArrowUp' => (-1, 0),
      'ArrowDown' => (1, 0),
      'ArrowLeft' => (0, -1),
      'ArrowRight' => (0, 1),
      _ => (0, 0),
    };
    if (dRow == 0 && dColumn == 0) return;
    key.preventDefault();
    final web.Element? grid = key.currentTarget as web.Element?;
    final web.Element? active = web.document.activeElement;
    if (grid == null || active == null) return;
    final web.NodeList cells = grid.querySelectorAll('.sticker-cell');
    int index = -1;
    for (int i = 0; i < cells.length; i++) {
      if (cells.item(i) == active) index = i;
    }
    if (index < 0) return;
    final int row = index ~/ _columns + dRow;
    final int column = index % _columns + dColumn;
    final int rows = (cells.length / _columns).ceil();
    if (row < 0 || row >= rows || column < 0 || column >= _columns) return;
    final int next = row * _columns + column;
    if (next >= cells.length) return;
    (cells.item(next)! as web.HTMLElement).focus();
  }

  @override
  Component build(BuildContext context) {
    return div(
      classes: enabled ? 'sticker-picker__grid' : 'sticker-picker__grid sticker-picker__grid--off',
      events: enabled ? const <String, void Function(web.Event)>{'keydown': _onKeyDown} : null,
      <Component>[child],
    );
  }
}

@css
List<StyleRule> get stickerPickerStyles => <StyleRule>[
  css('.sticker-picker').styles(
    position: const Position.relative(),
    width: const Unit.pixels(StickerPicker.width),
  ),
  css('.sticker-picker:focus, .sticker-picker:focus-visible').styles(raw: const <String, String>{'outline': 'none'}),
  css('.sticker-picker__box').styles(
    display: Display.flex,
    padding: const Padding.all(Unit.pixels(8)),
    border: Border.all(color: AppColors.border, width: const Unit.pixels(1)),
    radius: const BorderRadius.circular(Unit.pixels(16)),
    shadow: AppShadows.overlay,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(4)),
    backgroundColor: AppColors.white,
  ),
  css('.sticker-picker__header').styles(
    display: Display.flex,
    padding: const Padding.only(left: Unit.pixels(8)),
    justifyContent: JustifyContent.spaceBetween,
    alignItems: AlignItems.center,
  ),
  css('.sticker-picker__title').combine(AppTextStyles.eyebrow),
  css('.sticker-picker__grid').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(8)),
  ),
  css('.sticker-picker__grid--off').styles(opacity: 0.4),
  css('.sticker-picker__row').styles(display: Display.flex, gap: const Gap.column(Unit.pixels(8))),
  css('.sticker-picker__footer').styles(
    padding: const Padding.fromLTRB(Unit.pixels(8), Unit.pixels(8), Unit.pixels(8), Unit.pixels(4)),
    raw: <String, String>{'border-top': '1px solid ${AppColors.divider.value}'},
  ),
  css('.sticker-picker__cooldown').styles(
    display: Display.flex,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(8)),
  ),
  css('.sticker-picker__cooldown-text').styles(
    minWidth: Unit.zero,
    overflow: Overflow.hidden,
    flex: const Flex(grow: 0, shrink: 1, basis: Unit.auto),
    whiteSpace: WhiteSpace.noWrap,
  ),
  css('.sticker-picker__footer-text').combine(AppTextStyles.bodyXs).combine(const Styles(color: AppColors.muted)),
  css('.sticker-picker__footer-sending').styles(color: AppColors.primary, fontWeight: FontWeight.w600),
  css('.sticker-picker__footer-name').styles(color: AppColors.ink, fontWeight: FontWeight.w600),
];
