import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:brandnest/data/report_repository.dart';

/// US-14: send a deal in. The desk decides; this only queues it.
///
/// The screenshot is what makes a report checkable, so it is asked for first —
/// but words alone are still accepted, because a shopper standing in a shop
/// looking at a poster has something worth telling us and no screenshot to take.
Future<bool?> showReportSheet(BuildContext context) =>
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Padding(
        // Lifts the sheet clear of the keyboard while the note is being typed.
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: const _ReportSheet(),
      ),
    );

class _ReportSheet extends ConsumerStatefulWidget {
  const _ReportSheet();

  @override
  ConsumerState<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<_ReportSheet> {
  final _text = TextEditingController();
  XFile? _screenshot;
  bool _sending = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        // Keeps a modern phone's 12MP screenshot under the API's 6MB limit
        // without the shopper ever meeting an error about it.
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked != null && mounted) setState(() => _screenshot = picked);
    } catch (_) {
      if (mounted) _say('Could not open that image.');
    }
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    try {
      await ref
          .read(reportRepositoryProvider)
          .send(text: _text.text.trim(), screenshotPath: _screenshot?.path);
      ref.invalidate(myReportsProvider);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() => _sending = false);
        _say('Could not send that — try again.');
      }
    }
  }

  void _say(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canSend =
        !_sending && (_screenshot != null || _text.text.trim().isNotEmpty);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Report a deal', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Seen a bank discount or a sale we are missing? Send it in. '
              'We check it by hand, and you earn points if it holds up.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            _Attachment(
              screenshot: _screenshot,
              onCamera: () => _pick(ImageSource.camera),
              onGallery: () => _pick(ImageSource.gallery),
              onRemove: () => setState(() => _screenshot = null),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _text,
              maxLines: 3,
              maxLength: 500,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'What is the deal?',
                hintText: 'e.g. Meezan Bank 20% off at J. till Sunday',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Spacer(),
                FilledButton(
                  onPressed: canSend ? _send : null,
                  child: Text(_sending ? 'Sending…' : 'Send it in'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Attachment extends StatelessWidget {
  const _Attachment({
    required this.screenshot,
    required this.onCamera,
    required this.onGallery,
    required this.onRemove,
  });

  final XFile? screenshot;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final picked = screenshot;
    if (picked == null) {
      return Row(
        children: [
          OutlinedButton.icon(
            onPressed: onGallery,
            icon: const Icon(Icons.image_outlined),
            label: const Text('Screenshot'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: onCamera,
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('Photo'),
          ),
        ],
      );
    }
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(picked.path),
            width: 64,
            height: 84,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text('Attached', style: Theme.of(context).textTheme.bodyMedium)),
        IconButton(
          onPressed: onRemove,
          icon: const Icon(Icons.close),
          tooltip: 'Remove',
        ),
      ],
    );
  }
}
