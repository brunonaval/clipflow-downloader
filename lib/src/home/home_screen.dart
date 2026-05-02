import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../downloads/download_item.dart';
import '../downloads/download_options.dart';
import '../downloads/download_queue_controller.dart';
import 'mock_download_item.dart';

const _kGreen = Color(0xFF2E7D32);
const _kDivider = Color(0xFFE0E0E0);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;
  DownloadOptions _downloadOptions = const DownloadOptions();

  late final DownloadQueueController _queueController;

  @override
  void initState() {
    super.initState();
    _queueController = DownloadQueueController(
      initialItems: initialMockDownloadItems,
    );
  }

  Future<void> _handlePaste() async {
    String? url;
    try {
      final data = await Clipboard.getData('text/plain');
      final text = data?.text ?? '';
      if (text.isNotEmpty) {
        url = text;
      }
    } catch (_) {
      // Clipboard may be unavailable; proceed without URL.
    }

    if (!mounted) return;

    _queueController.addMockAuthorizedLink(
      sourceUrl: url,
      transferType: _downloadOptions.transferType,
      formatLabel: _downloadOptions.formatLabel,
      qualityLabel: _downloadOptions.qualityLabel,
      outputFolderLabel: _downloadOptions.outputFolderLabel,
    );

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link adicionado à fila mockada'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          const _MenuBar(),
          const Divider(height: 1, thickness: 1, color: _kDivider),
          _Toolbar(
            selectedTransferLabel: _downloadOptions.toolbarTransferLabel,
            selectedQualityLabel: _downloadOptions.toolbarQualityLabel,
            selectedFormatLabel: _downloadOptions.toolbarFormatLabel,
            selectedOutputFolderLabel: _downloadOptions.toolbarOutputFolderLabel,
            onTransferChanged: (type) =>
                setState(() => _downloadOptions = _downloadOptions.copyWith(transferType: type)),
            onQualityChanged: (value) =>
                setState(() => _downloadOptions = _downloadOptions.copyWith(qualityLabel: value)),
            onFormatChanged: (value) =>
                setState(() => _downloadOptions = _downloadOptions.copyWith(formatLabel: value)),
            onOutputFolderChanged: (value) => setState(
              () => _downloadOptions =
                  _downloadOptions.copyWith(outputFolderLabel: value),
            ),
            onPaste: _handlePaste,
          ),
          const Divider(height: 1, thickness: 1, color: _kDivider),
          _FilterTabs(
            selectedIndex: _selectedTab,
            itemCountLabel: _queueController.itemCountLabel,
            onChanged: (i) => setState(() => _selectedTab = i),
          ),
          const Divider(height: 1, thickness: 1, color: _kDivider),
          Expanded(
            child: ColoredBox(
              color: Colors.white,
              child: ListView.builder(
                itemCount: _queueController.itemCount,
                itemBuilder: (_, i) =>
                    _DownloadListItem(item: _queueController.items[i]),
              ),
            ),
          ),
          const _StatusBar(),
        ],
      ),
    );
  }
}

class _MenuBar extends StatelessWidget {
  const _MenuBar();

  static const _items = ['Arquivo', 'Editar', 'Ver', 'Ferramentas', 'Ajuda'];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      color: const Color(0xFFFAFAFA),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'ClipFlow Downloader',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            const VerticalDivider(
              width: 1,
              thickness: 1,
              indent: 8,
              endIndent: 8,
            ),
            ..._items.map(
              (item) => TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: const Size(0, 40),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: const RoundedRectangleBorder(),
                ),
                child: Text(item, style: const TextStyle(fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  final String selectedTransferLabel;
  final String selectedQualityLabel;
  final String selectedFormatLabel;
  final String selectedOutputFolderLabel;
  final ValueChanged<DownloadTransferType> onTransferChanged;
  final ValueChanged<String> onQualityChanged;
  final ValueChanged<String> onFormatChanged;
  final ValueChanged<String> onOutputFolderChanged;
  final VoidCallback onPaste;

  const _Toolbar({
    required this.selectedTransferLabel,
    required this.selectedQualityLabel,
    required this.selectedFormatLabel,
    required this.selectedOutputFolderLabel,
    required this.onTransferChanged,
    required this.onQualityChanged,
    required this.onFormatChanged,
    required this.onOutputFolderChanged,
    required this.onPaste,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: onPaste,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      elevation: 1,
                    ),
                    child: const Text(
                      'Colar link',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  _SelectorButton<DownloadTransferType>(
                    valueLabel: selectedTransferLabel,
                    options: const {
                      DownloadTransferType.video: 'Vídeo',
                      DownloadTransferType.audio: 'Áudio',
                      DownloadTransferType.subtitles: 'Legendas',
                      DownloadTransferType.audioTracks: 'Faixas de áudio',
                    },
                    onChanged: onTransferChanged,
                  ),
                  const SizedBox(width: 8),
                  _SelectorButton<String>(
                    valueLabel: selectedQualityLabel,
                    options: const {
                      'Ótima': 'Ótima',
                      '8K': '8K',
                      '4K': '4K',
                      '1080p': '1080p',
                      '720p': '720p',
                      '480p': '480p',
                      '360p': '360p',
                      '240p': '240p',
                    },
                    onChanged: onQualityChanged,
                  ),
                  const SizedBox(width: 8),
                  _SelectorButton<String>(
                    valueLabel: selectedFormatLabel,
                    options: const {
                      'Automático': 'Automático',
                      'MP4': 'MP4',
                      'MKV': 'MKV',
                      'MP3': 'MP3',
                      'M4A': 'M4A',
                    },
                    onChanged: onFormatChanged,
                  ),
                  const SizedBox(width: 8),
                  _SelectorButton<String>(
                    valueLabel: selectedOutputFolderLabel,
                    options: const {
                      'Vídeos': 'Vídeos',
                      'Downloads': 'Downloads',
                      'Imagens': 'Imagens',
                      'Documentos': 'Documentos',
                      'Navegar...': 'Navegar...',
                    },
                    onChanged: onOutputFolderChanged,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20),
            onPressed: () {},
            tooltip: 'Configurações',
            color: Colors.black54,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _SelectorButton<T> extends StatelessWidget {
  final String valueLabel;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  const _SelectorButton({
    required this.valueLabel,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      onSelected: onChanged,
      itemBuilder: (_) => options.entries
          .map((entry) => PopupMenuItem<T>(
                value: entry.key,
                child: Text(entry.value),
              ))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
          color: const Color(0xFFF8F8F8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              valueLabel,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: Colors.black45,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  final int selectedIndex;
  final String itemCountLabel;
  final ValueChanged<int> onChanged;

  const _FilterTabs({
    required this.selectedIndex,
    required this.itemCountLabel,
    required this.onChanged,
  });

  static const _tabs = [
    'Todos',
    'Vídeo',
    'Áudio',
    'Listas de Reprodução',
    'Canais',
    'Assinaturas',
    'IA',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_tabs.length, (i) {
                  final selected = i == selectedIndex;
                  return InkWell(
                    onTap: () => onChanged(i),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: selected ? _kGreen : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        _tabs[i],
                        style: TextStyle(
                          fontSize: 13,
                          color: selected ? _kGreen : Colors.black87,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          const VerticalDivider(
            width: 1,
            thickness: 1,
            indent: 8,
            endIndent: 8,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Text(
                  itemCountLabel,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.search, size: 18),
                  onPressed: () {},
                  tooltip: 'Buscar',
                  color: Colors.black54,
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: const Icon(Icons.sort, size: 18),
                  onPressed: () {},
                  tooltip: 'Ordenar',
                  color: Colors.black54,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DownloadListItem extends StatelessWidget {
  final DownloadItem item;

  const _DownloadListItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDownloading =
        item.status == DownloadStatus.downloading && item.progress > 0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 78,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D2D),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white54,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.metadataLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    if (isDownloading)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: LinearProgressIndicator(
                          value: item.progress,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation(_kGreen),
                          minHeight: 3,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _StatusBadge(item: item),
            ],
          ),
        ),
        Divider(
          height: 1,
          thickness: 1,
          color: Colors.grey.shade100,
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final DownloadItem item;

  const _StatusBadge({required this.item});

  static Color _colorFor(DownloadStatus s) => switch (s) {
        DownloadStatus.completed => Color(0xFF2E7D32),
        DownloadStatus.failed => Colors.red,
        DownloadStatus.canceled => Colors.grey,
        DownloadStatus.downloading => Colors.blue,
        DownloadStatus.ready => Colors.teal,
        _ => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    return Text(
      item.statusLabel,
      style: TextStyle(
        fontSize: 11,
        color: _colorFor(item.status),
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: _kGreen,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pronto para downloads autorizados',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Cole um link de conteúdo próprio, autorizado ou permitido pela plataforma',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white54),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              visualDensity: VisualDensity.compact,
            ),
            child: const Text(
              'Configurar motor',
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
