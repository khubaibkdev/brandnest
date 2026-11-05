import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brandnest/core/rewarded_ad_service.dart';
import 'package:brandnest/data/points_repository.dart';

/// Balance, streak, and the two ways to earn (US-10): a once-a-day check-in
/// and a capped number of rewarded ads. Both numbers come straight from the
/// server on every open — there is nothing device-local to go stale here.
class PointsSheet extends ConsumerStatefulWidget {
  const PointsSheet({super.key});

  @override
  ConsumerState<PointsSheet> createState() => _PointsSheetState();
}

class _PointsSheetState extends ConsumerState<PointsSheet> {
  bool _busy = false;

  Future<void> _checkIn() async {
    setState(() => _busy = true);
    try {
      final result = await ref.read(pointsRepositoryProvider).checkIn();
      ref.invalidate(pointsProvider);
      if (!result.awarded) _showMessage('Already checked in today.');
    } catch (_) {
      _showMessage('Could not check in — try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _watchAd() {
    setState(() => _busy = true);
    final clientRef =
        '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 32)}';
    ref.read(rewardedAdServiceProvider).watch(
      onEarned: () async {
        try {
          final result = await ref
              .read(pointsRepositoryProvider)
              .reportRewardedAd(clientRef);
          ref.invalidate(pointsProvider);
          if (!result.awarded) _showMessage("That's today's limit — come back tomorrow.");
        } catch (_) {
          _showMessage('Watched, but could not record the reward — try again.');
        } finally {
          if (mounted) setState(() => _busy = false);
        }
      },
      onFailed: (_) {
        if (mounted) setState(() => _busy = false);
        _showMessage('No ad available right now.');
      },
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = ref.watch(pointsProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: switch (status) {
          AsyncData(:final value) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${value.balance} points', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                value.streakDays > 0
                    ? '🔥 ${value.streakDays}-day streak'
                    : 'No streak yet — check in to start one',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              // US-18: shown apart from the balance, because these are earned
              // but not yet spendable — presenting them as one number would
              // promise more than the shopper actually has.
              if (value.pending > 0) ...[
                const SizedBox(height: 4),
                Text(
                  '+${value.pending} pending from orders — unlocks when your '
                  'return window closes',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy || value.checkedInToday ? null : _checkIn,
                child: Text(
                  value.checkedInToday
                      ? 'Checked in today'
                      : 'Check in for +10',
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _busy || value.rewardedAdsRemainingToday == 0
                    ? null
                    : _watchAd,
                child: Text(
                  value.rewardedAdsRemainingToday == 0
                      ? "That's today's limit"
                      : 'Watch an ad for +20 (${value.rewardedAdsRemainingToday} left today)',
                ),
              ),
            ],
          ),
          AsyncError() => const Text('Could not load your points right now.'),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}
