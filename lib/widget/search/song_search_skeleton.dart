import 'package:flutter/material.dart';

import '../../system/theme/theme.dart';

/// A placeholder shaped like a song row, shown while the YouTube results are
/// being fetched.
///
/// It mirrors the layout of [SongSearchTile] — a box where the art goes and two
/// bars where the title and the artist go — so the rows that arrive take the
/// place of the ones it stands for instead of the list jumping.
///
/// It does not shimmer on purpose: a repeating animation never lets a
/// `pumpAndSettle` in a test finish, and the bars already read as "loading"
/// next to the results above them.
class SongSearchTileSkeleton extends StatelessWidget {
  const SongSearchTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final placeholder = Theme.of(context).extraColors.secondary;

    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Container(
            margin: const EdgeInsets.only(left: 10, right: 10),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: placeholder.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _bar(placeholder, widthFactor: 0.6, height: 14),
                const SizedBox(height: 8),
                _bar(placeholder, widthFactor: 0.35, height: 11),
              ],
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _bar(Color color, {required double widthFactor, required double height}) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
