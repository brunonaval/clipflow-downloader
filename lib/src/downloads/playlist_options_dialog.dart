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
    final total = widget.playlist.entries.length;
    final selectedCount = _selectedIds.length;
    final allSelected = total > 0 && selectedCount == total;
    final canAdd = selectedCount > 0;

    return AlertDialog(
      title: const Text('Baixar playlist'),
      content: SizedBox(
        width: 700,
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
                      onChanged: total == 0
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
                    const Text('Selecionar todos'),
                  ],
                ),
                TextButton(
                  onPressed: selectedCount == 0
                      ? null
                      : () => setState(() => _selectedIds.clear()),
                  child: const Text('Limpar seleção'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (total == 0)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('Nenhum vídeo encontrado nesta playlist.'),
              )
            else
              Flexible(
                child: SizedBox(
                  height: 300,
                  child: ListView.separated(
                    itemCount: widget.playlist.entries.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
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
