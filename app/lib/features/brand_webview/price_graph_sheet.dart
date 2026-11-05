import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brandnest/data/price_history_repository.dart';
import 'package:brandnest/features/offers/offer_presentation.dart';

/// US-12. The graph answers "is this actually cheap?" — the question a
/// struck-through price on the brand's own page is designed to stop a shopper
/// asking. The verdict is computed by the API, never recomputed here.
Future<void> showPriceGraphSheet(
  BuildContext context, {
  required int productId,
  required String? productTitle,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _PriceGraphSheet(productId: productId, title: productTitle),
);

class _PriceGraphSheet extends ConsumerWidget {
  const _PriceGraphSheet({required this.productId, required this.title});

  final int productId;
  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(priceHistoryProvider(productId));
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: switch (history) {
          AsyncData(:final value) => PriceReport(title: title, history: value),
          AsyncError() => const _Message('Could not load the price history.'),
          _ => const _Message('Loading price history…'),
        },
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40),
    child: Center(child: Text(text)),
  );
}

class PriceReport extends StatelessWidget {
  const PriceReport({super.key, required this.title, required this.history});

  final String? title;
  final PriceHistory history;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = history.currentPrice;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The title names the one series the chart draws, so it needs no legend.
        if (title != null)
          Text(
            title!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium,
          ),
        const SizedBox(height: 4),
        if (current != null)
          Text(
            formatRupees(current),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        const SizedBox(height: 16),
        VerdictBanner(history: history),
        if (history.points.length > 1) ...[
          const SizedBox(height: 20),
          PriceChart(history: history),
        ],
        const SizedBox(height: 12),
        Text(
          _trackingNote(history.windowDays),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// Says what we actually watched. The Asli Sale rule is written against 90
  /// days; claiming that window while the crawl is younger would be the same
  /// overstatement the badge exists to call out.
  String _trackingNote(int days) => switch (days) {
    0 => 'We have not recorded a price for this product yet.',
    1 => 'Based on 1 day of price checks so far.',
    _ => 'Based on $days days of price checks so far.',
  };
}

class VerdictBanner extends StatelessWidget {
  const VerdictBanner({super.key, required this.history});

  final PriceHistory history;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, headline, color) = _presentation(theme);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The icon and the wording each carry the verdict on their own, so it
          // still reads without colour vision.
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(_explanation(), style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (IconData, String, Color) _presentation(ThemeData theme) =>
      switch (history.verdict) {
        PriceVerdict.genuine => (
          Icons.verified,
          'Asli Sale',
          const Color(0xFF2E7D32),
        ),
        PriceVerdict.preSaleMarkup => (
          Icons.warning_amber_rounded,
          'Price was raised first',
          theme.colorScheme.error,
        ),
        PriceVerdict.notLowest => (
          Icons.info_outline,
          'This is the usual price',
          theme.colorScheme.onSurfaceVariant,
        ),
        PriceVerdict.noHistory => (
          Icons.help_outline,
          'Not tracked long enough',
          theme.colorScheme.onSurfaceVariant,
        ),
      };

  String _explanation() {
    final typical = history.typicalPrice;
    return switch (history.verdict) {
      PriceVerdict.genuine =>
        'Cheaper than the ${formatRupees(typical!)} it normally sells for.',
      PriceVerdict.preSaleMarkup =>
        'It went up within the last 21 days, then came back down — so the '
            'discount is measured against a price it barely sold at.',
      PriceVerdict.notLowest =>
        '${formatRupees(typical!)} is what it has cost for most of this time, '
            'whatever the crossed-out price says.',
      PriceVerdict.noHistory =>
        'We have not seen this product long enough to judge its discount.',
    };
  }
}

/// A step line, because that is what the data is: a price holds until the day
/// it changes. One series, so there is nothing to key — the sheet's title says
/// what it is, and only the extremes and the usual price get labels.
class PriceChart extends StatelessWidget {
  const PriceChart({super.key, required this.history});

  final PriceHistory history;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 170,
      width: double.infinity,
      child: CustomPaint(
        painter: PriceChartPainter(
          history: history,
          line: theme.colorScheme.primary,
          surface: theme.colorScheme.surface,
          grid: theme.colorScheme.outlineVariant,
          labelStyle:
              theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ) ??
              const TextStyle(fontSize: 11),
        ),
      ),
    );
  }
}

class PriceChartPainter extends CustomPainter {
  PriceChartPainter({
    required this.history,
    required this.line,
    required this.surface,
    required this.grid,
    required this.labelStyle,
  });

  final PriceHistory history;
  final Color line;
  final Color surface;
  final Color grid;
  final TextStyle labelStyle;

  static const _leftGutter = 62.0;
  static const _bottomGutter = 20.0;
  static const _topPadding = 8.0;

  @override
  void paint(Canvas canvas, Size size) {
    final points = history.points;
    final prices = [for (final point in points) point.price];
    final high = prices.reduce((a, b) => a > b ? a : b);
    final low = prices.reduce((a, b) => a < b ? a : b);
    final plot = Rect.fromLTRB(
      _leftGutter,
      _topPadding,
      size.width,
      size.height - _bottomGutter,
    );

    // A price that never moved would divide by zero here; parking it on the
    // middle line says "flat" more honestly than pinning it to an edge.
    double yFor(double price) => high == low
        ? plot.center.dy
        : plot.bottom - (price - low) / (high - low) * plot.height;
    double xFor(int index) =>
        plot.left + plot.width * index / (points.length - 1);

    _gridLine(canvas, plot, yFor(high));
    _gridLine(canvas, plot, yFor(low));
    _usualPriceLine(canvas, plot, yFor);
    _steps(canvas, points, xFor, yFor);
    _latestPoint(canvas, xFor(points.length - 1), yFor(prices.last));

    _label(canvas, formatRupees(high), Offset(0, yFor(high) - 7));
    if (high != low) {
      _label(canvas, formatRupees(low), Offset(0, yFor(low) - 7));
    }
    _label(canvas, _axisDate(points.first.on), Offset(plot.left, plot.bottom + 4));
    _label(
      canvas,
      _axisDate(points.last.on),
      Offset(plot.right, plot.bottom + 4),
      alignRight: true,
    );
  }

  void _gridLine(Canvas canvas, Rect plot, double y) {
    canvas.drawLine(
      Offset(plot.left, y),
      Offset(plot.right, y),
      Paint()
        ..color = grid
        ..strokeWidth = 1,
    );
  }

  /// The level the verdict is judged against. Dashed, so it reads as a
  /// threshold rather than as one more gridline.
  void _usualPriceLine(Canvas canvas, Rect plot, double Function(double) yFor) {
    final typical = history.typicalPrice;
    if (typical == null) return;
    final paint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    final y = yFor(typical);
    for (var x = plot.left; x < plot.right; x += 8) {
      canvas.drawLine(Offset(x, y), Offset(x + 4, y), paint);
    }
  }

  void _steps(
    Canvas canvas,
    List<PricePoint> points,
    double Function(int) xFor,
    double Function(double) yFor,
  ) {
    final path = Path()..moveTo(xFor(0), yFor(points.first.price));
    for (var index = 1; index < points.length; index++) {
      path.lineTo(xFor(index), yFor(points[index - 1].price));
      path.lineTo(xFor(index), yFor(points[index].price));
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
  }

  /// Today's price, ringed in the surface colour so it stays legible sitting on
  /// the line it terminates.
  void _latestPoint(Canvas canvas, double x, double y) {
    canvas.drawCircle(Offset(x, y), 6, Paint()..color = surface);
    canvas.drawCircle(Offset(x, y), 4, Paint()..color = line);
  }

  void _label(Canvas canvas, String text, Offset at, {bool alignRight = false}) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, alignRight ? at.translate(-painter.width, 0) : at);
  }

  /// "25 Jul" — the axis has no room for a year, and the whole series sits
  /// inside one 90-day window anyway.
  String _axisDate(DateTime date) =>
      formatDate(date).replaceFirst(' ${date.year}', '');

  @override
  bool shouldRepaint(PriceChartPainter old) => old.history != history;
}
