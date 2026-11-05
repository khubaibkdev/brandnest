import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brandnest/core/image_urls.dart';
import 'package:brandnest/core/theme/theme.dart';
import 'package:brandnest/data/brand_repository.dart';
import 'package:brandnest/data/squad_repository.dart';
import 'package:brandnest/features/brand_webview/brand_webview_screen.dart';
import 'package:brandnest/features/offers/offer_presentation.dart';
import 'package:brandnest/features/squad/squad_board_screen.dart';

/// One pinned outfit: who it is for, the family's comments, and the way back
/// to the brand's page. Listens to the board, so a poll that lands while it is
/// open updates it too.
Future<void> showSquadItemSheet(
  BuildContext context, {
  required ValueNotifier<SquadBoard?> board,
  required int itemId,
  required Future<void> Function(BoardAction action) apply,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => ValueListenableBuilder<SquadBoard?>(
    valueListenable: board,
    builder: (sheetContext, current, _) {
      final item = current?.items.where((item) => item.id == itemId).firstOrNull;
      if (current == null || item == null) {
        // Someone took it down while the sheet was open.
        return const Padding(
          padding: EdgeInsets.all(AppSpace.xl),
          child: Text('This outfit was removed from the board.'),
        );
      }
      return _ItemSheet(board: current, item: item, apply: apply);
    },
  ),
);

class _ItemSheet extends ConsumerStatefulWidget {
  const _ItemSheet({required this.board, required this.item, required this.apply});

  final SquadBoard board;
  final SquadItem item;
  final Future<void> Function(BoardAction action) apply;

  @override
  ConsumerState<_ItemSheet> createState() => _ItemSheetState();
}

class _ItemSheetState extends ConsumerState<_ItemSheet> {
  final _comment = TextEditingController();
  late final _note = TextEditingController(text: widget.item.note);
  bool _sending = false;

  SquadBoard get _board => widget.board;
  SquadItem get _item => widget.item;

  bool get _canRemove => _item.addedBy == _board.myMemberId || _board.me.isOwner;

  @override
  void dispose() {
    _comment.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _comment.text.trim();
    if (body.isEmpty) return;
    setState(() => _sending = true);
    await widget.apply((squads) => squads.comment(_board.id, _item.id, body));
    if (!mounted) return;
    _comment.clear();
    setState(() => _sending = false);
  }

  Future<void> _saveNote() async {
    if (_note.text.trim() == (_item.note ?? '')) return;
    await widget.apply(
      (squads) => squads.setNote(_board.id, _item.id, _note.text.trim()),
    );
  }

  Future<void> _remove() async {
    Navigator.of(context).pop();
    await widget.apply((squads) => squads.remove(_board.id, _item.id));
  }

  void _openAtBrand() {
    final brand = (ref.read(brandsProvider).value ?? const [])
        .where((candidate) => candidate.slug == _item.brandSlug)
        .firstOrNull;
    if (brand == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_item.brandName} is not available right now')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BrandWebViewScreen(brand: brand, initialUrl: _item.url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final price = _item.price;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(AppSpace.l, 0, AppSpace.l, AppSpace.l),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: SquadItemImage(url: _item.imageUrl, width: 120, height: 160),
                ),
                const SizedBox(width: AppSpace.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_item.brandName, style: theme.textTheme.labelMedium),
                      Text(_item.title, style: theme.textTheme.titleMedium),
                      const SizedBox(height: AppSpace.s),
                      Text(
                        price == null ? 'Price not known' : formatRupees(price),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: AppSpace.s),
                      VoteButtons(
                        item: _item,
                        onVote: (value) => widget.apply(
                          (squads) => squads.vote(_board.id, _item.id, value),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.m),
            OutlinedButton.icon(
              onPressed: _openAtBrand,
              icon: const Icon(Icons.open_in_new),
              label: Text('Open on ${_item.brandName}'),
            ),
            const SizedBox(height: AppSpace.m),
            DropdownMenu<int?>(
              key: ValueKey(_item.assignedTo),
              expandedInsets: EdgeInsets.zero,
              label: const Text('Whose outfit'),
              initialSelection: _item.assignedTo,
              dropdownMenuEntries: [
                const DropdownMenuEntry(value: null, label: 'Not decided'),
                for (final member in _board.members)
                  DropdownMenuEntry(
                    value: member.id,
                    label: member.id == _board.myMemberId
                        ? '${member.displayName} (you)'
                        : member.displayName,
                  ),
              ],
              onSelected: (memberId) => widget.apply(
                (squads) => squads.assign(_board.id, _item.id, memberId),
              ),
            ),
            const SizedBox(height: AppSpace.m),
            TextField(
              controller: _note,
              maxLength: 300,
              decoration: const InputDecoration(
                labelText: 'Note',
                hintText: 'Size, colour, which function…',
              ),
              onEditingComplete: _saveNote,
              onTapOutside: (_) => _saveNote(),
            ),
            Text('Comments', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpace.s),
            if (_item.comments.isEmpty)
              Text(
                'No comments yet.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            for (final comment in _item.comments)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.s),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${_board.memberById(comment.memberId)?.displayName ?? 'Someone'}  ',
                        style: theme.textTheme.labelLarge,
                      ),
                      TextSpan(text: comment.body, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
            TextField(
              controller: _comment,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Say what you think',
                suffixIcon: IconButton(
                  onPressed: _sending ? null : _send,
                  icon: const Icon(Icons.send),
                  tooltip: 'Send comment',
                ),
              ),
              onSubmitted: (_) => _send(),
            ),
            if (_canRemove)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _remove,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remove from board'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Thumbs up / score / thumbs down. Tapping your current vote again takes it back.
class VoteButtons extends StatelessWidget {
  const VoteButtons({super.key, required this.item, required this.onVote});

  final SquadItem item;
  final void Function(int value) onVote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: () => onVote(item.myVote == 1 ? 0 : 1),
          isSelected: item.myVote == 1,
          icon: const Icon(Icons.thumb_up_outlined),
          selectedIcon: Icon(Icons.thumb_up, color: theme.colorScheme.primary),
          tooltip: item.myVote == 1 ? 'Take back your like' : 'Like this',
        ),
        Text(
          '${item.score}',
          semanticsLabel: 'Score ${item.score}',
          style: theme.textTheme.labelLarge?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: () => onVote(item.myVote == -1 ? 0 : -1),
          isSelected: item.myVote == -1,
          icon: const Icon(Icons.thumb_down_outlined),
          selectedIcon: Icon(Icons.thumb_down, color: theme.colorScheme.primary),
          tooltip: item.myVote == -1 ? 'Take back your dislike' : 'Not this one',
        ),
      ],
    );
  }
}

class SquadItemImage extends StatelessWidget {
  const SquadItemImage({
    super.key,
    required this.url,
    required this.width,
    required this.height,
  });

  final String? url;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: SizedBox(
        width: width,
        height: height,
        child: const Icon(Icons.checkroom_outlined),
      ),
    );
    final source = sizedImageUrl(url, width: (width * 3).round());
    if (source == null) return placeholder;
    return Image.network(
      source,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}
