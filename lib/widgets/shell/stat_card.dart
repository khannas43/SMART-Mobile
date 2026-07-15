import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../i18n/app_locale.dart';

class StatCardData {
  const StatCardData({
    required this.labelEn,
    required this.labelHi,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.barColor,
    this.onTap,
  });

  final String labelEn;
  final String labelHi;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final Color barColor;
  final VoidCallback? onTap;
}

class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.data});

  final StatCardData data;

  @override
  Widget build(BuildContext context) {
    AppLocaleScope.watch(context);
    final card = Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: data.bgColor.withValues(alpha: 0.6)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [data.bgColor.withValues(alpha: 0.5), kCard],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: data.bgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(data.icon, color: data.color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              data.value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: kText,
                height: 1.15,
              ),
              softWrap: true,
            ),
            const SizedBox(height: 4),
            Text(
              context.l(data.labelEn, data.labelHi),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: kMuted,
                height: 1.3,
              ),
              softWrap: true,
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: 1,
                minHeight: 3,
                backgroundColor: kBorder,
                color: data.barColor,
              ),
            ),
          ],
        ),
      ),
    );

    if (data.onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(16),
        child: card,
      ),
    );
  }
}

class StatSection extends StatelessWidget {
  const StatSection({
    super.key,
    required this.titleEn,
    required this.titleHi,
    required this.cards,
  });

  final String titleEn;
  final String titleHi;
  final List<StatCardData> cards;

  @override
  Widget build(BuildContext context) {
    AppLocaleScope.watch(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 22,
              decoration: BoxDecoration(
                color: kPrimaryRoyal,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              context.l(titleEn, titleHi),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: kText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 600;
            if (!wide) {
              return Column(
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    StatCard(data: cards[i]),
                  ],
                ],
              );
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                // Slightly shorter than the Android-tuned ratio: iOS's system font
                // line-height for the same fontSize renders taller, which overflowed
                // this Column by ~1px at the old ratio.
                childAspectRatio: 1.25,
              ),
              itemCount: cards.length,
              itemBuilder: (_, i) => StatCard(data: cards[i]),
            );
          },
        ),
      ],
    );
  }
}
