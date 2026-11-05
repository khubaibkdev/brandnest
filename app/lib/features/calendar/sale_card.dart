import 'package:flutter/material.dart';

import 'package:brandnest/data/app_database.dart';
import 'package:brandnest/features/calendar/sale_phase.dart';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String formatDay(DateTime day) => '${day.day} ${_months[day.month - 1]}';

/// The dates as a shopper would read them, or nothing at all when the brand
/// never announced any.
String saleDateRange(SaleEvent sale) {
  final startsAt = sale.startsAt;
  final endsAt = sale.endsAt;
  if (startsAt == null && endsAt == null) return '';
  if (startsAt == null) return 'until ${formatDay(endsAt!)}';
  if (endsAt == null) return 'from ${formatDay(startsAt)}';
  return '${formatDay(startsAt)} – ${formatDay(endsAt)}';
}

class SaleCard extends StatelessWidget {
  const SaleCard({super.key, required this.sale, required this.now});

  final SaleEvent sale;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ended = salePhase(sale, now) == SalePhase.ended;
    final dates = saleDateRange(sale);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    sale.brandName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: ended ? theme.colorScheme.outline : null,
                    ),
                  ),
                ),
                if (isVerified(sale)) const _VerifiedBadge(),
              ],
            ),
            const SizedBox(height: 4),
            Text(sale.title, style: theme.textTheme.bodyLarge),
            if (sale.discountText != null)
              Text(
                sale.discountText!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  ended ? Icons.event_busy : Icons.schedule,
                  size: 15,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(width: 6),
                Text(
                  saleCountdown(sale, now),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: ended
                        ? theme.colorScheme.outline
                        : theme.colorScheme.onSurface,
                  ),
                ),
                if (dates.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      dates,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.verified, size: 15, color: theme.colorScheme.primary),
        const SizedBox(width: 4),
        Text(
          'Verified',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
