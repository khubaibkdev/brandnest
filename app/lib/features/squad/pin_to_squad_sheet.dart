import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brandnest/core/theme/theme.dart';
import 'package:brandnest/data/squad_repository.dart';
import 'package:brandnest/features/brand_webview/product_reader.dart';
import 'package:brandnest/features/squad/squad_forms.dart';
import 'package:brandnest/features/squad/squad_presentation.dart';

/// Pin the product on screen to one of the shopper's squads (US-21).
/// Returns the squad's name when something was pinned.
Future<String?> showPinToSquadSheet(
  BuildContext context, {
  required String brandSlug,
  required DetectedPage page,
}) => showModalBottomSheet<String>(
  context: context,
  showDragHandle: true,
  builder: (_) => _PinSheet(brandSlug: brandSlug, page: page),
);

class _PinSheet extends ConsumerStatefulWidget {
  const _PinSheet({required this.brandSlug, required this.page});

  final String brandSlug;
  final DetectedPage page;

  @override
  ConsumerState<_PinSheet> createState() => _PinSheetState();
}

class _PinSheetState extends ConsumerState<_PinSheet> {
  int? _pinningTo;

  Future<void> _pin(int squadId, String squadName) async {
    setState(() => _pinningTo = squadId);
    try {
      await ref.read(squadRepositoryProvider).pin(
        squadId,
        brandSlug: widget.brandSlug,
        url: widget.page.url,
        title: widget.page.title ?? widget.page.url,
        imageUrl: widget.page.imageUrl,
        priceText: widget.page.price,
      );
      if (mounted) Navigator.of(context).pop(squadName);
    } catch (_) {
      if (!mounted) return;
      setState(() => _pinningTo = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not pin it — try again.')),
      );
    }
  }

  Future<void> _createThenPin() async {
    final board = await showCreateSquadSheet(context);
    if (board != null) await _pin(board.id, board.name);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final squads = ref.watch(mySquadsProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpace.l, 0, AppSpace.l, AppSpace.m),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pin to a squad', style: theme.textTheme.titleLarge),
            if (widget.page.title != null)
              Text(
                widget.page.title!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: AppSpace.s),
            switch (squads) {
              AsyncData(:final value) => Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final squad in value)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(squad.name),
                        subtitle: Text(squadEventLine(squad.eventType, squad.eventDate)),
                        trailing: _pinningTo == squad.id
                            ? const SizedBox.square(
                                dimension: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.push_pin_outlined),
                        onTap: _pinningTo == null ? () => _pin(squad.id, squad.name) : null,
                      ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.add),
                      title: Text(value.isEmpty ? 'Start a squad for this' : 'New squad'),
                      onTap: _pinningTo == null ? _createThenPin : null,
                    ),
                  ],
                ),
              ),
              AsyncError() => const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpace.l),
                child: Text('Could not load your squads — are you online?'),
              ),
              _ => const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpace.l),
                child: Center(child: CircularProgressIndicator()),
              ),
            },
          ],
        ),
      ),
    );
  }
}
