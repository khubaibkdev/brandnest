import 'package:brandnest/data/app_database.dart';

/// Where a sale sits relative to now. A sale with no end date is running until
/// the deals desk retires it — that is what the brand told us, so that is what
/// we say.
enum SalePhase { running, upcoming, ended }

SalePhase salePhase(SaleEvent sale, DateTime now) {
  final startsAt = sale.startsAt;
  final endsAt = sale.endsAt;
  if (startsAt != null && startsAt.isAfter(now)) return SalePhase.upcoming;
  if (endsAt != null && endsAt.isBefore(now)) return SalePhase.ended;
  return SalePhase.running;
}

String saleCountdown(SaleEvent sale, DateTime now) => switch (salePhase(sale, now)) {
  SalePhase.upcoming => _phrase('Starts', calendarDaysBetween(now, sale.startsAt!)),
  SalePhase.running when sale.endsAt == null => 'Live now',
  SalePhase.running => _phrase('Ends', calendarDaysBetween(now, sale.endsAt!)),
  SalePhase.ended => _ended(calendarDaysBetween(sale.endsAt!, now)),
};

/// Only the desk's own verdict earns the badge; an event that has ended keeps
/// its place in the calendar but loses the tick.
bool isVerified(SaleEvent sale) =>
    sale.status == 'verified' || sale.status == 'live';

/// Whole days apart on the calendar, not 24-hour blocks: a sale starting at 9am
/// tomorrow starts "tomorrow" whether it is now noon or 11pm.
int calendarDaysBetween(DateTime from, DateTime to) => DateTime(to.year, to.month, to.day)
    .difference(DateTime(from.year, from.month, from.day))
    .inDays;

/// True when the sale is under way on [day]. Undated sales are not on any day —
/// they show as "on now" instead of being drawn across the whole grid.
bool coversDay(SaleEvent sale, DateTime day) {
  final startsAt = sale.startsAt;
  final endsAt = sale.endsAt;
  if (startsAt == null && endsAt == null) return false;
  final dayStart = DateTime(day.year, day.month, day.day);
  final nextDay = dayStart.add(const Duration(days: 1));
  final hasStarted = startsAt == null || startsAt.isBefore(nextDay);
  final notOverYet = endsAt == null || !endsAt.isBefore(dayStart);
  return hasStarted && notOverYet;
}

bool isUndated(SaleEvent sale) => sale.startsAt == null && sale.endsAt == null;

String _phrase(String verb, int days) => switch (days) {
  0 => '$verb today',
  1 => '$verb tomorrow',
  _ => '$verb in $days days',
};

String _ended(int days) => switch (days) {
  0 => 'Ended today',
  1 => 'Ended yesterday',
  _ => 'Ended $days days ago',
};
