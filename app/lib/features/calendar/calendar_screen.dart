import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brandnest/data/app_database.dart';
import 'package:brandnest/data/sale_repository.dart';
import 'package:brandnest/features/calendar/month_view.dart';
import 'package:brandnest/features/calendar/sale_card.dart';
import 'package:brandnest/features/calendar/sale_phase.dart';

/// Verified sales, as a list and as a month. Reads come from the Drift cache,
/// so the calendar is readable with no signal at all.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    try {
      await ref.read(saleRepositoryProvider).refresh();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offline — showing the saved calendar.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sales = ref.watch(saleEventsProvider);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sale calendar'),
          bottom: const TabBar(tabs: [Tab(text: 'List'), Tab(text: 'Month')]),
        ),
        body: switch (sales) {
          AsyncData(:final value) when value.isEmpty => const _EmptyState(),
          AsyncData(:final value) => TabBarView(
            children: [
              _SaleList(sales: value, now: DateTime.now(), onRefresh: _refresh),
              MonthView(sales: value, now: DateTime.now(), onRefresh: _refresh),
            ],
          ),
          AsyncError(:final error) => Center(child: Text('$error')),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _SaleList extends StatelessWidget {
  const _SaleList({
    required this.sales,
    required this.now,
    required this.onRefresh,
  });

  final List<SaleEvent> sales;
  final DateTime now;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final grouped = {
      for (final phase in SalePhase.values)
        phase: sales.where((sale) => salePhase(sale, now) == phase).toList(),
    };
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          for (final phase in SalePhase.values)
            if (grouped[phase]!.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                child: Text(
                  _heading(phase),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              for (final sale in grouped[phase]!) SaleCard(sale: sale, now: now),
            ],
        ],
      ),
    );
  }
}

String _heading(SalePhase phase) => switch (phase) {
  SalePhase.running => 'On now',
  SalePhase.upcoming => 'Coming up',
  SalePhase.ended => 'Recently ended',
};

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'No verified sales yet. Every sale here is checked by a person '
          'before it appears.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
