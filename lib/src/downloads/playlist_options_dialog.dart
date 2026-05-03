import 'package:flutter/material.dart';

import '../engine/yt_dlp/yt_dlp_playlist_result.dart';

class PlaylistOptionsDialog extends StatefulWidget {
  final YtDlpPlaylistResult playlist;

  const PlaylistOptionsDialog({super.key, required this.playlist});

  @override
  State<PlaylistOptionsDialog> createState() => _PlaylistOptionsDialogState();
}

class _PlaylistOptionsDialogState extends State<PlaylistOptionsDialog> {
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.playlist.entries.map((e) => e.id).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final allSelected =
        widget.playlist.entries.isNotEmpty &&
        _selectedIds.length == widget.playlist.entries.length;
    final canAdd = _selectedIds.isNotEmpty;

    return AlertDialog(
      title: const Text('Baixar playlist'),
      content: SizedBox(
        width: 640,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.playlist.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if ((widget.playlist.authorLabel?.trim().isNotEmpty ?? false))
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  widget.playlist.authorLabel!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '${widget.playlist.itemCount} vídeos',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: allSelected,
              title: const Text('Selecionar todos'),
              onChanged: widget.playlist.entries.isEmpty
                  ? null
                  : (value) {
                      setState(() {
                        if (value == true) {
                          _selectedIds = widget.playlist.entries
                              .map((e) => e.id)
                              .toSet();
                        } else {
                          _selectedIds = <String>{};
                        }
                      });
                    },
            ),
            const SizedBox(height: 4),
            Flexible(
              child: SizedBox(
                height: 280,
                child: ListView.builder(
                  itemCount: widget.playlist.entries.length,
                  itemBuilder: (_, index) {
                    final entry = widget.playlist.entries[index];
                    final checked = _selectedIds.contains(entry.id);
                    final details = <String>[
                      if ((entry.durationLabel?.trim().isNotEmpty ?? false))
                        entry.durationLabel!,
                      if ((entry.authorLabel?.trim().isNotEmpty ?? false))
                        entry.authorLabel!,
                    ];
                    return CheckboxListTile(
                      key: Key('playlist-entry-${entry.id}'),
                      dense: true,
                      value: checked,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedIds.add(entry.id);
                          } else {
                            _selectedIds.remove(entry.id);
                          }
                        });
                      },
                      title: Text(
                        entry.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: details.isEmpty
                          ? null
                          : Text(
                              details.join(' · '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: canAdd
              ? () {
                  final selected = widget.playlist.entries
                      .where((entry) => _selectedIds.contains(entry.id))
                      .toList();
                  Navigator.pop(context, selected);
                }
              : null,
          child: const Text('Adicionar à fila'),
        ),
      ],
    );
  }
}
