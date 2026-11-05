import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brandnest/core/auth_service.dart';
import 'package:brandnest/data/app_database.dart';
import 'package:brandnest/data/bank_offer.dart';
import 'package:brandnest/data/offer_directory_repository.dart';
import 'package:brandnest/features/offers/my_cards.dart';
import 'package:brandnest/features/offers/my_cards_sheet.dart';
import 'package:brandnest/features/offers/offer_presentation.dart';
import 'package:brandnest/features/reports/my_reports_sheet.dart';
import 'package:brandnest/features/reports/report_sheet.dart';

/// Every bank discount we have verified, grouped by bank and filterable down to
/// the cards the shopper actually carries. Reads from the Drift cache, so it
/// works with no signal — and offers that ran out while it was cached are
/// dropped on the way out of the repository, not left on screen.
class DirectoryScreen extends ConsumerStatefulWidget {
  const DirectoryScreen({super.key});

  @override
  ConsumerState<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends ConsumerState<DirectoryScreen> {
  /// Null until the shopper says otherwise: saving cards is itself a request to
  /// use them, so the filter switches on the first time some are saved.
  bool? _myCardsOnly;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    try {
      await ref.read(offerDirectoryRepositoryProvider).refresh();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offline — showing the saved offers.')),
      );
    }
  }

  Future<void> _reportDeal() async {
    final sent = await showReportSheet(context);
    if (sent == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thanks — we will check it and let you know.'),
        ),
      );
    }
  }

  void _editCards(List<BankOffer> offers) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => MyCardsSheet(options: bankCardOptions(offers)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final offers = ref.watch(directoryOffersProvider);
    final cards = ref.watch(myCardsProvider).value ?? const <MyCard>[];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank discounts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.inbox_outlined),
            tooltip: 'My reports',
            onPressed: () => showMyReportsSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.credit_card),
            tooltip: 'My cards',
            onPressed: () => _editCards(offers.value ?? const []),
          ),
        ],
      ),
      // US-14 lives here because this tab is the directory those reports feed:
      // every offer on this screen was entered by hand until now.
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _reportDeal,
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Report a deal'),
      ),
      body: switch (offers) {
        AsyncData(:final value) when value.isEmpty => const _EmptyState(),
        AsyncData(:final value) => _Directory(
          offers: value,
          cards: cards,
          myCardsOnly: _myCardsOnly ?? cards.isNotEmpty,
          onFilterChanged: (on) => setState(() => _myCardsOnly = on),
          onEditCards: () => _editCards(value),
          onRefresh: _refresh,
        ),
        AsyncError(:final error) => Center(child: Text('$error')),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Directory extends StatelessWidget {
  const _Directory({
    required this.offers,
    required this.cards,
    required this.myCardsOnly,
    required this.onFilterChanged,
    required this.onEditCards,
    required this.onRefresh,
  });

  final List<BankOffer> offers;
  final List<MyCard> cards;
  final bool myCardsOnly;
  final ValueChanged<bool> onFilterChanged;
  final VoidCallback onEditCards;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final visible = myCardsOnly
        ? offers.where((offer) => offerMatchesMyCards(offer, cards)).toList()
        : offers;
    // The list already arrives grouped by bank, so insertion order is the order
    // the sections render in.
    final byBank = <String, List<BankOffer>>{};
    for (final offer in visible) {
      byBank.putIfAbsent(offer.bankName, () => []).add(offer);
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const _LinkGoogleBanner(),
          if (cards.isEmpty)
            _CardsPrompt(onEditCards: onEditCards)
          else
            _CardsFilter(
              myCardsOnly: myCardsOnly,
              onFilterChanged: onFilterChanged,
              onEditCards: onEditCards,
            ),
          if (visible.isEmpty) const _NoneMatchMyCards(),
          for (final entry in byBank.entries) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
              child: Text(
                entry.key,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            for (final offer in entry.value) _OfferCard(offer: offer),
          ],
        ],
      ),
    );
  }
}

/// Link-on-demand (US-9): the guest's anonymous token already saves cards
/// fine, so this isn't a sign-in wall — it just says what linking buys, and
/// only shows up while there is something to gain from it.
class _LinkGoogleBanner extends ConsumerWidget {
  const _LinkGoogleBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null || !user.isAnonymous) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Link your Google account so your saved cards survive a reinstall '
              'or a new phone.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _link(context, ref),
                child: const Text('Link Google account'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _link(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authServiceProvider).linkGoogleAccount();
      await ref.read(offerDirectoryRepositoryProvider).reconcileMyCards();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not link Google account.')),
      );
    }
  }
}

/// Shown until the shopper has told us anything: the directory is browsable
/// without it, so this asks rather than blocks.
class _CardsPrompt extends StatelessWidget {
  const _CardsPrompt({required this.onEditCards});

  final VoidCallback onEditCards;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tell us which cards you carry and we will show only the discounts '
              'you can actually claim.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onEditCards,
                child: const Text('Choose my cards'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardsFilter extends StatelessWidget {
  const _CardsFilter({
    required this.myCardsOnly,
    required this.onFilterChanged,
    required this.onEditCards,
  });

  final bool myCardsOnly;
  final ValueChanged<bool> onFilterChanged;
  final VoidCallback onEditCards;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FilterChip(
          label: const Text('My cards only'),
          selected: myCardsOnly,
          onSelected: onFilterChanged,
        ),
        const Spacer(),
        TextButton(onPressed: onEditCards, child: const Text('Edit cards')),
      ],
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.offer});

  final BankOffer offer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(offerBrand(offer)),
        subtitle: Text('${offerCardTypes(offer)}\n${offerValidity(offer)}'),
        isThreeLine: true,
        trailing: Text(
          offerSaving(offer),
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        onTap: () => showModalBottomSheet<void>(
          context: context,
          builder: (_) => OfferDetailSheet(offer: offer),
        ),
      ),
    );
  }
}

class _NoneMatchMyCards extends StatelessWidget {
  const _NoneMatchMyCards();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 40, 16, 16),
      child: Text(
        'No verified discounts for your cards right now. Turn the filter off to '
        'see every bank we cover.',
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'No bank discounts yet. Every offer here is checked against the '
          "bank's own page by a person before it appears.",
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
