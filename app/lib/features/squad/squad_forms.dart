import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brandnest/core/theme/theme.dart';
import 'package:brandnest/data/squad_repository.dart';
import 'package:brandnest/features/calendar/sale_card.dart';
import 'package:brandnest/features/squad/squad_presentation.dart';

/// Start a squad. Returns the new board, or null if the sheet was dismissed.
Future<SquadBoard?> showCreateSquadSheet(BuildContext context) =>
    showModalBottomSheet<SquadBoard>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _CreateSquadSheet(),
    );

/// Join from a link ([inviteCode] given) or by typing the code in.
Future<SquadBoard?> showJoinSquadSheet(
  BuildContext context, {
  String? inviteCode,
}) => showModalBottomSheet<SquadBoard>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _JoinSquadSheet(initialCode: inviteCode),
);

class _CreateSquadSheet extends ConsumerStatefulWidget {
  const _CreateSquadSheet();

  @override
  ConsumerState<_CreateSquadSheet> createState() => _CreateSquadSheetState();
}

class _CreateSquadSheetState extends ConsumerState<_CreateSquadSheet> {
  final _name = TextEditingController();
  final _budget = TextEditingController();
  final _myName = TextEditingController();
  SquadEventType _type = SquadEventType.mehndi;
  DateTime? _date;
  bool _saving = false;

  bool get _canSave =>
      !_saving && _name.text.trim().isNotEmpty && _myName.text.trim().isNotEmpty;

  @override
  void dispose() {
    _name.dispose();
    _budget.dispose();
    _myName.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 730)),
      initialDate: _date ?? today.add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final board = await ref.read(squadRepositoryProvider).create(
        name: _name.text.trim(),
        eventType: _type,
        eventDate: _date,
        budgetTotal: double.tryParse(_budget.text.replaceAll(',', '')),
        displayName: _myName.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(board);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not create the squad — try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SheetFrame(
      title: 'New squad',
      children: [
        TextField(
          controller: _name,
          autofocus: true,
          maxLength: 80,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Event',
            hintText: "e.g. Ayesha's Mehndi",
          ),
          onChanged: (_) => setState(() {}),
        ),
        Wrap(
          spacing: AppSpace.s,
          children: [
            for (final type in SquadEventType.values)
              ChoiceChip(
                label: Text(type.label),
                selected: type == _type,
                onSelected: (_) => setState(() => _type = type),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.s),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.event_outlined),
          title: Text(_date == null ? 'Add the date' : formatDay(_date!)),
          subtitle: _date == null
              ? null
              : Text(squadEventLine(_type, _date), style: theme.textTheme.bodySmall),
          onTap: _pickDate,
        ),
        TextField(
          controller: _budget,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Total budget (optional)',
            prefixText: 'PKR ',
          ),
        ),
        const SizedBox(height: AppSpace.m),
        _MyNameField(controller: _myName, onChanged: () => setState(() {})),
        const SizedBox(height: AppSpace.l),
        FilledButton(
          onPressed: _canSave ? _save : null,
          child: Text(_saving ? 'Creating…' : 'Create squad'),
        ),
      ],
    );
  }
}

class _JoinSquadSheet extends ConsumerStatefulWidget {
  const _JoinSquadSheet({this.initialCode});

  final String? initialCode;

  @override
  ConsumerState<_JoinSquadSheet> createState() => _JoinSquadSheetState();
}

class _JoinSquadSheetState extends ConsumerState<_JoinSquadSheet> {
  late final _code = TextEditingController(text: widget.initialCode);
  final _myName = TextEditingController();
  SquadInvite? _invite;
  String? _problem;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialCode != null) _lookUp();
  }

  @override
  void dispose() {
    _code.dispose();
    _myName.dispose();
    super.dispose();
  }

  Future<void> _lookUp() async {
    setState(() {
      _busy = true;
      _problem = null;
    });
    try {
      final invite = await ref
          .read(squadRepositoryProvider)
          .invite(_code.text.trim());
      if (!mounted) return;
      setState(() {
        _invite = invite;
        _problem = invite == null ? 'No squad has that code. Check it and try again.' : null;
      });
      if (invite != null && invite.alreadyMember) {
        final board = await ref.read(squadRepositoryProvider).board(invite.squadId);
        if (mounted) Navigator.of(context).pop(board);
      }
    } catch (_) {
      if (mounted) setState(() => _problem = 'Could not check the code — are you online?');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _join() async {
    setState(() => _busy = true);
    try {
      final board = await ref
          .read(squadRepositoryProvider)
          .join(_code.text.trim(), _myName.text.trim());
      if (mounted) Navigator.of(context).pop(board);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _problem = 'Could not join — try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final invite = _invite;
    return _SheetFrame(
      title: invite == null ? 'Join a squad' : invite.name,
      children: [
        if (invite == null) ...[
          TextField(
            controller: _code,
            autofocus: widget.initialCode == null,
            textCapitalization: TextCapitalization.characters,
            maxLength: 8,
            style: theme.textTheme.titleLarge?.copyWith(letterSpacing: 4),
            decoration: const InputDecoration(labelText: 'Invite code'),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _lookUp(),
          ),
          FilledButton(
            onPressed: _busy || _code.text.trim().length < 8 ? null : _lookUp,
            child: Text(_busy ? 'Checking…' : 'Find squad'),
          ),
        ] else ...[
          Text(
            '${squadEventLine(invite.eventType, invite.eventDate)} · '
            '${invite.memberCount} ${invite.memberCount == 1 ? 'person' : 'people'} planning',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpace.l),
          _MyNameField(controller: _myName, onChanged: () => setState(() {})),
          const SizedBox(height: AppSpace.l),
          FilledButton(
            onPressed: _busy || _myName.text.trim().isEmpty ? null : _join,
            child: Text(_busy ? 'Joining…' : 'Join squad'),
          ),
        ],
        if (_problem != null) ...[
          const SizedBox(height: AppSpace.m),
          Text(_problem!, style: TextStyle(color: theme.colorScheme.error)),
        ],
      ],
    );
  }
}

/// Guests have no name on their account, so every squad asks for the one
/// family will recognise on the board.
class _MyNameField extends StatelessWidget {
  const _MyNameField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    maxLength: 40,
    textCapitalization: TextCapitalization.words,
    decoration: const InputDecoration(
      labelText: 'Your name',
      helperText: 'As the family knows you, e.g. Sana Phupho',
    ),
    onChanged: (_) => onChanged(),
  );
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpace.l,
        0,
        AppSpace.l,
        AppSpace.l + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpace.m),
            ...children,
          ],
        ),
      ),
    ),
  );
}
