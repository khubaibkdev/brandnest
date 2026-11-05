import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brandnest/core/theme/theme.dart';
import 'package:brandnest/data/squad_repository.dart';
import 'package:brandnest/features/squad/squad_board_screen.dart';
import 'package:brandnest/features/squad/squad_forms.dart';
import 'package:brandnest/features/squad/squad_presentation.dart';

/// Shaadi Squad (US-21): every event this shopper is planning with family.
class SquadsScreen extends ConsumerStatefulWidget {
  const SquadsScreen({super.key});

  @override
  ConsumerState<SquadsScreen> createState() => _SquadsScreenState();
}

class _SquadsScreenState extends ConsumerState<SquadsScreen> {
  @override
  void initState() {
    super.initState();
    ref.listenManual(pendingInviteProvider, (_, code) {
      if (code != null) _joinFromLink(code);
    }, fireImmediately: true);
  }

  Future<void> _joinFromLink(String code) async {
    // Wait for the frame: a cold-start link arrives before the tab is built.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    ref.read(pendingInviteProvider.notifier).handled();
    _openBoard(await showJoinSquadSheet(context, inviteCode: code));
  }

  Future<void> _create() async => _openBoard(await showCreateSquadSheet(context));

  Future<void> _joinWithCode() async => _openBoard(await showJoinSquadSheet(context));

  void _openBoard(SquadBoard? board) {
    if (board == null || !mounted) return;
    ref.invalidate(mySquadsProvider);
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => SquadBoardScreen(squadId: board.id, initialBoard: board),
          ),
        )
        .then((_) => ref.invalidate(mySquadsProvider));
  }

  @override
  Widget build(BuildContext context) {
    final squads = ref.watch(mySquadsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shaadi Squads'),
        actions: [
          TextButton.icon(
            onPressed: _joinWithCode,
            icon: const Icon(Icons.vpn_key_outlined),
            label: const Text('Join with code'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: const Text('New squad'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(mySquadsProvider.future),
        child: switch (squads) {
          AsyncData(:final value) when value.isEmpty => const _EmptyState(),
          AsyncData(:final value) => ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.m,
              AppSpace.s,
              AppSpace.m,
              // Clear of the FAB and the floating nav bar.
              AppSpace.xl * 4,
            ),
            itemCount: value.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpace.s),
            itemBuilder: (_, index) => _SquadCard(
              squad: value[index],
              onTap: () => Navigator.of(context)
                  .push(
                    MaterialPageRoute<void>(
                      builder: (_) => SquadBoardScreen(squadId: value[index].id),
                    ),
                  )
                  .then((_) => ref.invalidate(mySquadsProvider)),
            ),
          ),
          AsyncError() => const _Message(
            'Squads need a connection — the board is shared with your family.',
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _SquadCard extends StatelessWidget {
  const _SquadCard({required this.squad, required this.onTap});

  final SquadSummary squad;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.m),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(squad.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      squadEventLine(squad.eventType, squad.eventDate),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpace.s),
                    Text(
                      '${squad.memberCount} '
                      '${squad.memberCount == 1 ? 'person' : 'people'} · '
                      '${squad.itemCount} '
                      '${squad.itemCount == 1 ? 'outfit' : 'outfits'} pinned',
                      style: theme.textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // A ListView so pull-to-refresh still works on an empty screen.
    return ListView(
      padding: const EdgeInsets.all(AppSpace.l),
      children: [
        const SizedBox(height: AppSpace.xl),
        Icon(Icons.groups_outlined, size: 48, color: theme.colorScheme.primary),
        const SizedBox(height: AppSpace.m),
        Text(
          'Plan the shaadi wardrobe together',
          style: theme.textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpace.s),
        Text(
          'Start a squad for the mehndi or baraat, invite the family on '
          'WhatsApp, and pin outfits from any brand. Everyone votes, and each '
          'person sees what their outfits cost against their own budget.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(AppSpace.l),
    children: [
      const SizedBox(height: AppSpace.xl),
      Text(text, textAlign: TextAlign.center),
    ],
  );
}
