import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../engine/yt_dlp/yt_dlp_playlist_result.dart';

class PlaylistOptionsDialog extends StatefulWidget {
  final YtDlpPlaylistResult playlist;

  const PlaylistOptionsDialog({super.key, required this.playlist});

  @override
  State<PlaylistOptionsDialog> createState() => _PlaylistOptionsDialogState();
}

class _PlaylistOptionsDialogState extends State<PlaylistOptionsDialog> {
  late Set<int> _selectedIndexes;

  @override
  void initState() {
    super.initState();
    _selectedIndexes = <int>{};
    for (var i = 0; i < widget.playlist.entries.length; i++) {
      if (_isEntryAvailable(widget.playlist.entries[i])) {
        _selectedIndexes.add(i);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.playlist.entries.length;
    final availableIndexes = <int>{};
    for (var i = 0; i < total; i++) {
      if (_isEntryAvailable(widget.playlist.entries[i])) {
        availableIndexes.add(i);
      }
    }
    final selectedCount = _selectedIndexes.length;
    final availableCount = availableIndexes.length;
    final allSelected = availableCount > 0 && selectedCount == availableCount;
    final canAdd = selectedCount > 0;

    final size = MediaQuery.sizeOf(context);
    final dialogWidth = math.min(900.0, size.width * 0.8);
    final dialogHeight = math.min(720.0, size.height * 0.85);

    return AlertDialog(
      title: const Text('Baixar playlist'),
      content: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
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
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '$total vídeos',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Selecionados: $selectedCount de $total',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: allSelected,
                      onChanged: availableCount == 0
                          ? null
                          : (value) {
                              setState(() {
                                if (value == true) {
                                  _selectedIndexes = Set<int>.from(
                                    availableIndexes,
                                  );
                                } else {
                                  _selectedIndexes = <int>{};
                                }
                              });
                            },
                    ),
                    const Text('Selecionar todos'),
                  ],
                ),
                TextButton(
                  onPressed: selectedCount == 0
                      ? null
                      : () => setState(() => _selectedIndexes.clear()),
                  child: const Text('Limpar seleção'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (total == 0)
              const Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('Nenhum vídeo encontrado nesta playlist.'),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: widget.playlist.entries.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final entry = widget.playlist.entries[index];
                    final available = _isEntryAvailable(entry);
                    final unavailable = !available;
                    final checked = _selectedIndexes.contains(index);
                    final details = <String>[
                      if ((entry.durationLabel?.trim().isNotEmpty ?? false))
                        entry.durationLabel!,
                      if ((entry.authorLabel?.trim().isNotEmpty ?? false))
                        entry.authorLabel!,
                    ];
                    return InkWell(
                      key: Key('playlist-entry-$index'),
                      onTap: unavailable
                          ? null
                          : () {
                              setState(() {
                                if (checked) {
                                  _selectedIndexes.remove(index);
                                } else {
                                  _selectedIndexes.add(index);
                                }
                              });
                            },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: checked
                                ? const Color(0xFF2E7D32)
                                : Colors.grey.shade300,
                            width: checked ? 1.2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: checked
                              ? const Color(0xFFEAF7EE)
                              : Colors.white,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _EntryThumbnail(entry: entry, index: index),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          entry.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (unavailable)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFDECEC),
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFFF4B7B7),
                                            ),
                                          ),
                                          child: const Text(
                                            'Indisponível',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFFB91C1C),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                    ],
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
                              onChanged: unavailable
                                  ? null
                                  : (value) {
                                      setState(() {
                                        if (value == true) {
                                          _selectedIndexes.add(index);
                                        } else {
                                          _selectedIndexes.remove(index);
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
                  final selected = <YtDlpPlaylistEntry>[];
                  for (var i = 0; i < widget.playlist.entries.length; i++) {
                    if (_selectedIndexes.contains(i)) {
                      selected.add(widget.playlist.entries[i]);
                    }
                  }
                  Navigator.pop(context, selected);
                }
              : null,
          child: const Text('Adicionar à fila'),
        ),
      ],
    );
  }

  bool _isEntryAvailable(YtDlpPlaylistEntry entry) {
    final title = entry.title.trim().toLowerCase();
    final hasInvalidTitle =
        title.isEmpty ||
        title.contains('[private video]') ||
        title.contains('private video') ||
        title.contains('deleted video');
    final hasUrl = entry.url.trim().isNotEmpty;
    final hasId = entry.id.trim().isNotEmpty;
    return !hasInvalidTitle && (hasUrl || hasId);
  }
}

class _EntryThumbnail extends StatelessWidget {
  final YtDlpPlaylistEntry entry;
  final int index;

  const _EntryThumbnail({required this.entry, required this.index});

  @override
  Widget build(BuildContext context) {
    final url = entry.thumbnailUrl;
    if (url != null && url.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          url,
          key: Key('playlist-thumb-$index'),
          width: 78,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _placeholder(index),
        ),
      );
    }
    return _placeholder(index);
  }

  Widget _placeholder(int i) {
    return Container(
      key: Key('playlist-thumb-fallback-$i'),
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
