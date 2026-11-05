import 'package:flutter_test/flutter_test.dart';

import 'package:brandnest/data/squad_repository.dart';
import 'package:brandnest/features/squad/squad_presentation.dart';

Map<String, dynamic> _boardJson() => {
  'id': 7,
  'name': "Ayesha's Mehndi",
  'event_type': 'mehndi',
  'event_date': '2026-12-20',
  'budget_total': '100000.00',
  'planned_total': '15000.00',
  'invite_code': 'K7Q2MXAB',
  'invite_url': 'https://example.ngrok-free.app/i/K7Q2MXAB',
  'my_member_id': 2,
  'members': [
    {'id': 1, 'display_name': 'Ammi', 'role': 'owner', 'budget_personal': null, 'planned': '0'},
    {'id': 2, 'display_name': 'Sana', 'role': 'member', 'budget_personal': '20000.00', 'planned': '15000.00'},
  ],
  'items': [
    {
      'id': 3,
      'brand_slug': 'alkaram',
      'brand_name': 'Alkaram',
      'url': 'https://alkaramstudio.com/products/red',
      'title': 'Red Lehenga',
      'image_url': null,
      'price': '15000.00',
      'added_by': 1,
      'assigned_to': 2,
      'note': null,
      'score': 1,
      'my_vote': 1,
      'comments': [
        {'id': 9, 'member_id': 1, 'body': 'Perfect', 'created_at': '2026-11-05T10:00:00Z'},
      ],
    },
  ],
};

void main() {
  group('reading a board', () {
    final board = SquadBoard.fromJson(_boardJson());

    test('money arrives as decimal strings', () {
      expect(board.budgetTotal, 100000);
      expect(board.me.budget, 20000);
      expect(board.members.first.budget, isNull);
      expect(board.items.single.price, 15000);
    });

    test('me is the viewer\'s own membership', () {
      expect(board.me.displayName, 'Sana');
      expect(board.members.first.isOwner, isTrue);
    });

    test('an item points at its assignee and carries its comments', () {
      final item = board.items.single;

      expect(board.memberById(item.assignedTo)?.displayName, 'Sana');
      expect(item.comments.single.body, 'Perfect');
    });

    test('an unknown event type reads as other', () {
      expect(SquadEventType.parse('dholki'), SquadEventType.other);
    });
  });

  group('invite links', () {
    test('an invite path yields its code, upper-cased', () {
      expect(
        inviteCodeFromLink(Uri.parse('https://x.ngrok-free.app/i/k7q2mxab')),
        'K7Q2MXAB',
      );
    });

    test('any other path is not an invite', () {
      expect(inviteCodeFromLink(Uri.parse('https://x.ngrok-free.app/i/')), isNull);
      expect(inviteCodeFromLink(Uri.parse('https://x.ngrok-free.app/admin')), isNull);
      expect(inviteCodeFromLink(Uri.parse('https://x.ngrok-free.app/i/A/B')), isNull);
    });
  });

  group('page prices', () {
    test('storefront text with grouping parses', () {
      expect(parsePagePrice('12,990.00'), 12990);
      expect(parsePagePrice(' 4500 '), 4500);
    });

    test('missing or garbled text gives no price', () {
      expect(parsePagePrice(null), isNull);
      expect(parsePagePrice('Rs.'), isNull);
    });
  });

  group('the event line', () {
    final today = DateTime(2026, 11, 5);

    test('counts the days to the event', () {
      expect(
        squadEventLine(SquadEventType.mehndi, DateTime(2026, 12, 20), today: today),
        'Mehndi · 20 Dec · in 45 days',
      );
    });

    test('says tomorrow and done in words', () {
      expect(
        squadEventLine(SquadEventType.baraat, DateTime(2026, 11, 6), today: today),
        'Baraat · 6 Nov · tomorrow',
      );
      expect(
        squadEventLine(SquadEventType.walima, DateTime(2026, 11, 1), today: today),
        'Walima · 1 Nov · done',
      );
    });

    test('no date is just the event type', () {
      expect(squadEventLine(SquadEventType.eid, null), 'Eid');
    });
  });
}
