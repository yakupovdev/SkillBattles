import 'package:material_ui/material_ui.dart';

/// Three small pips; the first [division] are filled with [color].
///
/// Hidden for a single-division league ([division] is `null`).
final class DivisionPips extends StatelessWidget {
  const DivisionPips({
    required this.division,
    required this.color,
    required this.emptyColor,
    super.key,
  });

  final int? division;
  final Color color;
  final Color emptyColor;

  @override
  Widget build(BuildContext context) {
    final int? filled = division;
    if (filled == null) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: <Widget>[
        for (int i = 1; i <= 3; i++)
          SizedBox(
            width: 16,
            height: 4,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: i <= filled ? color : emptyColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
      ],
    );
  }
}
