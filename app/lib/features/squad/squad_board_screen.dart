import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brandnest/core/theme/theme.dart';
import 'package:brandnest/data/squad_repository.dart';
import 'package:brandnest/features/offers/offer_presentation.dart';
import 'package:brandnest/features/squad/squad_item_sheet.dart';
import 'package:brandnest/features/squad/squad_presentation.dart';

/// How often an open board re-reads itself. No websockets in v1
/// (ARCHITECTURE §1): family members' pins and votes arrive on this beat.
const _pollEvery = Duration(seconds: 20);

/// One action against the board, answered with the whole new board.
typedef BoardAction = Future<SquadBoard> Function(SquadRepository squads);

class SquadBoardScreen extends ConsumerStatefulWidget {
  const SquadBoardScreen({super.key, required this.squadId, this.initialBoard});

  final int squadId;

  /// Skips the first load when the caller already has the board (just
  /// created or joined).
  final SquadBoard? initialBoard;

  @override
  ConsumerState<SquadBoardScreen> createState() => _SquadBoardScreenState();
}

class _SquadBoardScreenState extends ConsumerState<SquadBoardScreen> {
  late final ValueNotifier<SquadBoard?> _board = ValueNotifier(widget.initialBoard);
  Timer? _poll;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialBoard == null) _reload();
    _poll = Timer.periodic(_pollEvery, (_) => _reload());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _board.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    try {
      final board = await ref.read(squadRepositoryProvider).board(widget.squadId);
      if (!mounted) return;
      _board.value = board;
      setState(() => _loadFailed = false);
    } catch (_) {
      // A missed poll is not worth interrupting anyone for; the next one retries.
      if (mounted && _board.value == null) setState(() => _loadFailed = true);
    }
  }

  Future<void> _apply(BoardAction action) async {
    try {
      final board = await action(ref.read(squadRepositoryProvider));
      if (mounted) _board.value = board;
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That did not go through — try again.')),
      );
    }
  }

  Future<void> _editMyBudget(SquadBoard board) async {
    final budget = await showDialog<double?>(
      context: context,
      builder: (_) => _BudgetDialog(current: board.me.budget),
    );
    // The dialog answers -1 for "clear", null for "cancel".
    if (budget == null) return;
    await _apply(
      (squads) => squads.setMyBudget(board.id, budget < 0 ? null : budget),
    );
  }

  Future<void> _invite(SquadBoard board) async {
    final opened = await shareInviteOnWhatsApp(board);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('WhatsApp is not installed. Code: ${board.inviteCode}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SquadBoard?>(
      valueListenable: _board,
      builder: (context, board, _) => Scaffold(
        appBar: AppBar(
          title: Text(board?.name ?? 'Squad'),
          actions: [
            if (board != null)
              IconButton(
                onPressed: () => _invite(board),
                icon: const Icon(Icons.person_add_alt_1_outlined),
                tooltip: 'Invite family on WhatsApp',
              ),
          ],
        ),
        body: switch (board) {
          null when _loadFailed => Center(
            child: TextButton(
              onPressed: _reload,
              child: const Text('Could not load the board. Tap to retry.'),
            ),
          ),
          null => const Center(child: CircularProgressIndicator()),
          final board => RefreshIndicator(
            onRefresh: _reload,
            child: _BoardBody(
              board: board,
              onEditMyBudget: () => _editMyBudget(board),
              onInvite: () => _invite(board),
              onVote: (item, value) =>
                  _apply((squads) => squads.vote(board.id, item.id, value)),
              onOpenItem: (item) => showSquadItemSheet(
                context,
                board: _board,
                itemId: item.id,
                apply: _apply,
              ),
            ),
          ),
        },
      ),
    );
  }
}

class _BoardBody extends StatelessWidget {
  const _BoardBody({
    required this.board,
    required this.onEditMyBudget,
    required this.onInvite,
    required this.onVote,
    required this.onOpenItem,
  });

  final SquadBoard board;
  final VoidCallback onEditMyBudget;
  final VoidCallback onInvite;
  final void Function(SquadItem item, int value) onVote;
  final void Function(SquadItem item) onOpenItem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpace.xl),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.m, 0, AppSpace.m, AppSpace.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                squadEventLine(board.eventType, board.eventDate),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpace.m),
              _BudgetMeter(
                label: 'Planned so far',
                planned: board.plannedTotal,
                budget: board.budgetTotal,
              ),
            ],
          ),
        ),
        _MembersStrip(board: board, onEditMyBudget: onEditMyBudget, onInvite: onInvite),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.m, AppSpace.l, AppSpace.m, AppSpace.s),
          child: Text('Pinned outfits', style: theme.textTheme.titleMedium),
        ),
        if (board.items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.m),
            child: Text(
              'Open any brand, find an outfit and tap the pin in the address '
              'bar. It shows up here for everyone in the squad.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        for (final item in board.items)
          _ItemCard(
            item: item,
            assignee: board.memberById(item.assignedTo),
            onTap: () => onOpenItem(item),
            onVote: (value) => onVote(item, value),
          ),
      ],
    );
  }
}

/// Planned spend against a budget. Being over is said in words, not only in
/// the bar's colour.
class _BudgetMeter extends StatelessWidget {
  const _BudgetMeter({required this.label, required this.planned, this.budget});

  final String label;
  final double planned;
  final double? budget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final budget = this.budget;
    final over = budget != null && planned > budget;
    final figures = theme.textTheme.titleMedium?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelMedium),
        const SizedBox(height: AppSpace.xs),
        Text(
          budget == null
              ? formatRupees(planned)
              : '${formatRupees(planned)} of ${formatRupees(budget)}',
          style: figures,
        ),
        if (budget != null && budget > 0) ...[
          const SizedBox(height: AppSpace.s),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: (planned / budget).clamp(0, 1),
              minHeight: 6,
              color: over ? theme.colorScheme.error : theme.colorScheme.primary,
            ),
          ),
          if (over) ...[
            const SizedBox(height: AppSpace.xs),
            Text(
              '${formatRupees(planned - budget)} over budget',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _MembersStrip extends StatelessWidget {
  const _MembersStrip({
    required this.board,
    required this.onEditMyBudget,
    required this.onInvite,
  });

  final SquadBoard board;
  final VoidCallback onEditMyBudget;
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 112,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.m),
        children: [
          for (final member in board.members)
            Padding(
              padding: const EdgeInsets.only(right: AppSpace.s),
              child: _MemberCard(
                member: member,
                isMe: member.id == board.myMemberId,
                onTap: member.id == board.myMemberId ? onEditMyBudget : null,
              ),
            ),
          SizedBox(
            width: 112,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              onPressed: onInvite,
              icon: const Icon(Icons.add),
              label: Text('Invite', style: theme.textTheme.labelLarge),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member, required this.isMe, this.onTap});

  final SquadMember member;
  final bool isMe;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final budget = member.budget;
    final over = budget != null && member.planned > budget;
    return SizedBox(
      width: 152,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.s + AppSpace.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMe ? '${member.displayName} (you)' : member.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                if (member.isOwner)
                  Text('Started the squad', style: theme.textTheme.labelSmall),
                const Spacer(),
                Text(
                  formatRupees(member.planned),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  budget == null
                      ? (isMe ? 'Tap to set your budget' : 'No budget set')
                      : over
                      ? '${formatRupees(member.planned - budget)} over'
                      : 'of ${formatRupees(budget)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: over
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.item,
    required this.assignee,
    required this.onTap,
    required this.onVote,
  });

  final SquadItem item;
  final SquadMember? assignee;
  final VoidCallback onTap;
  final void Function(int value) onVote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final price = item.price;
    return Card(
      margin: const EdgeInsets.fromLTRB(AppSpace.m, 0, AppSpace.m, AppSpace.s),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SquadItemImage(url: item.imageUrl, width: 96, height: 128),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.s + AppSpace.xs,
                  AppSpace.s + AppSpace.xs,
                  AppSpace.xs,
                  AppSpace.xs,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.brandName, style: theme.textTheme.labelSmall),
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      price == null ? 'Price not known' : formatRupees(price),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      assignee == null ? 'Not for anyone yet' : 'For ${assignee!.displayName}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Row(
                      children: [
                        VoteButtons(item: item, onVote: onVote),
                        const Spacer(),
                        if (item.comments.isNotEmpty) ...[
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: AppSpace.xs),
                          Text(
                            '${item.comments.length}',
                            style: theme.textTheme.labelMedium,
                          ),
                          const SizedBox(width: AppSpace.s),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Answers the new budget, -1 to clear it, or null if cancelled.
class _BudgetDialog extends StatefulWidget {
  const _BudgetDialog({required this.current});

  final double? current;

  @override
  State<_BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends State<_BudgetDialog> {
  late final _amount = TextEditingController(
    text: widget.current?.round().toString() ?? '',
  );

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Your budget'),
    content: TextField(
      controller: _amount,
      autofocus: true,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        prefixText: 'PKR ',
        helperText: 'What you plan to spend on your outfits',
      ),
    ),
    actions: [
      if (widget.current != null)
        TextButton(
          onPressed: () => Navigator.of(context).pop(-1.0),
          child: const Text('Clear'),
        ),
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          final amount = double.tryParse(_amount.text.replaceAll(',', ''));
          if (amount != null && amount >= 0) Navigator.of(context).pop(amount);
        },
        child: const Text('Save'),
      ),
    ],
  );
}
