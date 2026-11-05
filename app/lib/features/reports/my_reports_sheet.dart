import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brandnest/data/report_repository.dart';
import 'package:brandnest/features/offers/offer_presentation.dart';

/// What happened to the deals someone sent in (US-14). The push tells them
/// once; this is where they can look it up afterwards.
Future<void> showMyReportsSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _MyReportsSheet(),
    );

class _MyReportsSheet extends ConsumerWidget {
  const _MyReportsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(myReportsProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('My reports', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            switch (reports) {
              AsyncData(:final value) when value.isEmpty => const _Message(
                'You have not sent any deals in yet.',
              ),
              AsyncData(:final value) => Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: value.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, index) => _ReportTile(report: value[index]),
                ),
              ),
              AsyncError() => const _Message('Could not load your reports.'),
              _ => const _Message('Loading…'),
            },
          ],
        ),
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({required this.report});

  final DealReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, label, colour) = switch (report.status) {
      ReportStatus.accepted => (
        Icons.verified,
        'Verified · +${report.pointsAwarded} points',
        const Color(0xFF2E7D32),
      ),
      ReportStatus.rejected => (
        Icons.do_not_disturb_on_outlined,
        'Could not be verified',
        theme.colorScheme.onSurfaceVariant,
      ),
      ReportStatus.waiting => (
        Icons.hourglass_empty,
        'Waiting on our check',
        theme.colorScheme.onSurfaceVariant,
      ),
    };
    return ListTile(
      contentPadding: EdgeInsets.zero,
      // Icon and wording both carry the outcome, so it reads without colour.
      leading: Icon(icon, color: colour),
      title: Text(
        report.text?.isNotEmpty == true ? report.text! : 'Screenshot only',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text('$label · ${formatDate(report.createdAt)}'),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Center(child: Text(text)),
  );
}
