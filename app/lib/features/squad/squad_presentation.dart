import 'package:url_launcher/url_launcher.dart';

import 'package:brandnest/data/squad_repository.dart';
import 'package:brandnest/features/calendar/sale_card.dart';

/// "Mehndi · 20 Dec · in 45 days" — the line under a squad's name.
String squadEventLine(SquadEventType type, DateTime? date, {DateTime? today}) {
  if (date == null) return type.label;
  final now = today ?? DateTime.now();
  final days = DateTime(date.year, date.month, date.day)
      .difference(DateTime(now.year, now.month, now.day))
      .inDays;
  final when = switch (days) {
    0 => 'today',
    1 => 'tomorrow',
    > 1 => 'in $days days',
    _ => 'done',
  };
  return '${type.label} · ${formatDay(date)} · $when';
}

/// Opens WhatsApp with the invite ready to send to a family group. The code is
/// in the message too, for anyone whose link opens a browser instead of the app.
Future<bool> shareInviteOnWhatsApp(SquadBoard board) {
  final message =
      'Join our ${board.name} squad on BrandNest so we can plan outfits '
      'together: ${board.inviteUrl}\n\n'
      'Or open BrandNest → Squads → Join with code: ${board.inviteCode}';
  return launchUrl(
    Uri.https('wa.me', '/', {'text': message}),
    mode: LaunchMode.externalApplication,
  );
}
