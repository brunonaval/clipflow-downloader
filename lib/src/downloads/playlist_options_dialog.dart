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
                    return InkWell(
                      key: Key('playlist-entry-${entry.id}'),
                      onTap: () {
                        setState(() {
                          if (checked) {
                            _selectedIds.remove(entry.id);
                          } else {
                            _selectedIds.add(entry.id);
                          }
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _EntryThumbnail(entry: entry),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (details.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        details.join(' · '),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Checkbox(
                              value: checked,
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedIds.add(entry.id);
                                  } else {
                                    _selectedIds.remove(entry.id);
                                  }
                                });
                              },
                            ),
                          ],
                        ),
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

class _EntryThumbnail extends StatelessWidget {
  final YtDlpPlaylistEntry entry;

  const _EntryThumbnail({required this.entry});

  @override
  Widget build(BuildContext context) {
    final url = entry.thumbnailUrl;
    if (url != null && url.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          url,
          key: Key('playlist-thumb-${entry.id}'),
          width: 78,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _placeholder(entry.id),
        ),
      );
    }
    return _placeholder(entry.id);
  }

  Widget _placeholder(String id) {
    return Container(
      key: Key('playlist-thumb-fallback-$id'),
      width: 78,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(Icons.play_arrow_rounded, color: Colors.white54),
    );
  }
}
