import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brandnest/features/brand_webview/offer_chips.dart';

import '../../fixtures.dart';

void main() {
  testWidgets('a brand with no offers takes no space', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: OfferChips(offers: []))),
    );

    expect(find.byType(ActionChip), findsNothing);
    expect(tester.getSize(find.byType(OfferChips)).height, 0);
  });

  testWidgets('tapping a chip explains the offer in full', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OfferChips(
            offers: [
              offerWith(
                bankName: 'Bank Alfalah',
                cardTypes: const ['credit'],
                discountPct: 20,
                maxDiscountAmount: 5000,
                minSpend: 6000,
                channel: 'both',
                validTo: DateTime(2026, 8, 16),
                proofUrl: 'https://www.bankalfalah.com/',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Bank Alfalah 20% off'), findsOneWidget);

    await tester.tap(find.byType(ActionChip));
    await tester.pumpAndSettle();

    expect(find.text('Verified offer'), findsOneWidget);
    expect(find.text('Credit'), findsOneWidget);
    expect(find.text('Minimum spend PKR 6,000'), findsOneWidget);
    expect(find.text('Up to PKR 5,000 off'), findsOneWidget);
    expect(find.text('Valid till 16 Aug 2026'), findsOneWidget);
    expect(find.text('Online and in store'), findsOneWidget);
    expect(find.text('See this offer on the bank site'), findsOneWidget);
  });

  testWidgets('an offer with no proof page shows no proof link', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: OfferChips(offers: [offerWith()]))),
    );
    await tester.tap(find.byType(ActionChip));
    await tester.pumpAndSettle();

    expect(find.textContaining('bank site'), findsNothing);
  });
}
