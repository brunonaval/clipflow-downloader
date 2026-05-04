import 'package:flutter/material.dart';

import 'download_format_option.dart';
import 'download_format_selector.dart';
import 'download_item.dart';
import 'download_options.dart';
import 'download_options_dialog_result.dart';
import 'download_preset.dart';

class DownloadOptionsDialog extends StatefulWidget {
  final DownloadItem item;
  final DownloadOptions initialOptions;

  const DownloadOptionsDialog({
    super.key,
    required this.item,
    required this.initialOptions,
  });

  @override
  State<DownloadOptionsDialog> createState() => _DownloadOptionsDialogState();
}

class _DownloadOptionsDialogState extends State<DownloadOptionsDialog> {
  static const DownloadFormatSelector _selector = DownloadFormatSelector();

  late DownloadTransferType _transferType;
  late String _qualityLabel;
  late String _formatLabel;
  String? _selectedFormatId;

  List<DownloadFormatOption> get _formats => widget.item.availableFormats;

  @override
  void initState() {
    super.initState();
    _transferType = widget.initialOptions.transferType;
    _qualityLabel = widget.initialOptions.qualityLabel;
    _formatLabel = widget.initialOptions.formatLabel;
    _selectedFormatId =
        (widget.item.selectedFormatId?.trim().isNotEmpty ?? false)
        ? widget.item.selectedFormatId
        : (_formats.isNotEmpty ? _formats.first.id : null);
  }

  @override
  Widget build(BuildContext context) {
    final canStart =
        _formats.isNotEmpty && (_selectedFormatId?.trim().isNotEmpty ?? false);

    return AlertDialog(
      title: const Text('Baixar vídeo'),
      content: SizedBox(
        width: 680,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _Header(item: widget.item),
              const SizedBox(height: 14),
              const Text(
                'Opções',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _dropdownField<DownloadTransferType>(
                    label: 'Transferir',
                    value: _transferType,
                    options: const {
                      DownloadTransferType.video: 'Vídeo',
                      DownloadTransferType.audio: 'Áudio',
                      DownloadTransferType.subtitles: 'Legendas',
                    },
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _transferType = value;
                        _syncSelectionWithPreset();
                      });
                    },
                  ),
                  _dropdownField<String>(
                    label: 'Contêiner',
                    value: _formatLabel,
                    options: const {
                      'Automático': 'Automático',
                      'MP4': 'MP4',
                      'MKV': 'MKV',
                      'M4A': 'M4A',
                      'WEBM': 'WEBM',
                    },
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _formatLabel = value;
                        _syncSelectionWithPreset();
                      });
                    },
                  ),
                  _dropdownField<String>(
                    label: 'Qualidade',
                    value: _qualityLabel,
                    options: const {
                      'Ótima': 'Ótima',
                      '1080p': '1080p',
                      '720p': '720p',
                      '480p': '480p',
                      '360p': '360p',
                      '240p': '240p',
                    },
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _qualityLabel = value;
                        _syncSelectionWithPreset();
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Formatos disponíveis',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              if (_formats.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('Nenhum formato disponível.'),
                )
              else
                SizedBox(
                  height: 290,
                  child: ListView.separated(
                    itemCount: _formats.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final format = _formats[index];
                      final selected = _selectedFormatId == format.id;
                      return _FormatCard(
                        key: Key('manual-format-${format.id}'),
                        format: format,
                        selected: selected,
                        onTap: () =>
                            setState(() => _selectedFormatId = format.id),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: canStart
              ? () => Navigator.pop(
                  context,
                  DownloadOptionsDialogResult(
                    transferType: _transferType,
                    qualityLabel: _qualityLabel,
                    formatLabel: _formatLabel,
                    selectedFormatId: _selectedFormatId!,
                    startDownload: true,
                  ),
                )
              : null,
          child: const Text('Baixar'),
        ),
      ],
    );
  }

  Widget _dropdownField<T>({
    required String label,
    required T value,
    required Map<T, String> options,
    required ValueChanged<T?> onChanged,
  }) {
    return SizedBox(
      width: 205,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            onChanged: onChanged,
            items: options.entries
                .map(
                  (entry) => DropdownMenuItem<T>(
                    value: entry.key,
                    child: Text(entry.value),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  void _syncSelectionWithPreset() {
    if (_formats.isEmpty) {
      _selectedFormatId = null;
      return;
    }
    final selected = _selector.selectRecommendedFormatId(
      formats: _formats,
      preset: DownloadPreset(
        transferType: _transferType,
        qualityLabel: _qualityLabel,
        formatLabel: _formatLabel,
      ),
    );
    _selectedFormatId =
        selected ??
        _selectedFormatId ??
        (_formats.isNotEmpty ? _formats.first.id : null);
  }
}

class _Header extends StatelessWidget {
  final DownloadItem item;

  const _Header({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(6), child: _thumbnail()),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if ((item.authorLabel?.trim().isNotEmpty ?? false))
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    item.authorLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  item.durationLabel,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _thumbnail() {
    final url = item.thumbnailUrl;
    if (url != null && url.trim().isNotEmpty) {
      return Image.network(
        url,
        width: 108,
        height: 62,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: 108,
      height: 62,
      color: const Color(0xFF2D2D2D),
      alignment: Alignment.center,
      child: const Icon(Icons.play_arrow_rounded, color: Colors.white54),
    );
  }
}

class _FormatCard extends StatelessWidget {
  final DownloadFormatOption format;
  final bool selected;
  final VoidCallback onTap;

  const _FormatCard({
    super.key,
    required this.format,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final base = _friendlyMainLabel(format);
    final details = <String>[
      if (format.qualityLabel.trim().isNotEmpty) format.qualityLabel,
      if (format.sizeLabel.trim().isNotEmpty) format.sizeLabel,
    ];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? const Color(0xFF2E7D32) : Colors.grey.shade300,
              width: selected ? 1.4 : 1,
            ),
            color: selected ? const Color(0xFFEAF7EE) : Colors.white,
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 18,
                color: selected ? const Color(0xFF2E7D32) : Colors.grey,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            base,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (format.isRecommended)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF7EE),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: const Color(0xFFB8DFC3),
                              ),
                            ),
                            child: const Text(
                              'Recomendado',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF2E7D32),
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
            ],
          ),
        ),
      ),
    );
  }

  String _friendlyMainLabel(DownloadFormatOption f) {
    if (f.kind == DownloadFormatKind.audio) {
      return '${f.formatLabel} · Áudio';
    }
    return '${f.formatLabel} · ${f.qualityLabel}';
  }
}
