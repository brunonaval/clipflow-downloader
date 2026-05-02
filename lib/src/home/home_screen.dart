import 'package:flutter/material.dart';

import 'mock_download_item.dart';

const _kGreen = Color(0xFF2E7D32);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;
  String _selectedType = 'Vídeo';
  String _selectedQuality = 'Ótima';
  String _selectedFormat = 'MP4';
  String _selectedFolder = 'Vídeos';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          const _MenuBar(),
          _Toolbar(
            selectedType: _selectedType,
            selectedQuality: _selectedQuality,
            selectedFormat: _selectedFormat,
            selectedFolder: _selectedFolder,
            onTypeChanged: (v) => setState(() => _selectedType = v),
            onQualityChanged: (v) => setState(() => _selectedQuality = v),
            onFormatChanged: (v) => setState(() => _selectedFormat = v),
            onFolderChanged: (v) => setState(() => _selectedFolder = v),
          ),
          const Divider(height: 1, thickness: 1),
          _FilterTabs(
            selectedIndex: _selectedTab,
            onChanged: (i) => setState(() => _selectedTab = i),
          ),
          const Divider(height: 1, thickness: 1),
          Expanded(
            child: ColoredBox(
              color: Colors.white,
              child: ListView.builder(
                itemCount: kMockItems.length,
                itemBuilder: (_, i) => _DownloadListItem(item: kMockItems[i]),
              ),
            ),
          ),
          const _StatusBar(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Menu bar
// ---------------------------------------------------------------------------

class _MenuBar extends StatelessWidget {
  const _MenuBar();

  static const _items = ['Arquivo', 'Editar', 'Ver', 'Ferramentas', 'Ajuda'];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      color: const Color(0xFFF0F0F0),
      child: Row(
        children: _items
            .map(
              (item) => TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 44),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: const RoundedRectangleBorder(),
                ),
                child: Text(item, style: const TextStyle(fontSize: 13)),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Toolbar
// ---------------------------------------------------------------------------

class _Toolbar extends StatelessWidget {
  final String selectedType;
  final String selectedQuality;
  final String selectedFormat;
  final String selectedFolder;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<String> onQualityChanged;
  final ValueChanged<String> onFormatChanged;
  final ValueChanged<String> onFolderChanged;

  const _Toolbar({
    required this.selectedType,
    required this.selectedQuality,
    required this.selectedFormat,
    required this.selectedFolder,
    required this.onTypeChanged,
    required this.onQualityChanged,
    required this.onFormatChanged,
    required this.onFolderChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      elevation: 0,
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
                  _SelectorButton(
                    prefix: 'Transferir',
                    value: selectedType,
                    options: const [
                      'Vídeo',
                      'Áudio',
                      'Legendas',
                      'Faixas de áudio',
                    ],
                    onChanged: onTypeChanged,
                  ),
                  const SizedBox(width: 8),
                  _SelectorButton(
                    prefix: 'Qualidade',
                    value: selectedQuality,
                    options: const [
                      'Ótima',
                      '8K',
                      '4K',
                      '1080p',
                      '720p',
                      '480p',
                      '360p',
                      '240p',
                    ],
                    onChanged: onQualityChanged,
                  ),
                  const SizedBox(width: 8),
                  _SelectorButton(
                    prefix: 'Para',
                    value: selectedFormat,
                    options: const ['Automático', 'MP4', 'MKV', 'MP3', 'M4A'],
                    onChanged: onFormatChanged,
                  ),
                  const SizedBox(width: 8),
                  _SelectorButton(
                    prefix: 'Guardar em',
                    value: selectedFolder,
                    options: const [
                      'Vídeos',
                      'Downloads',
                      'Imagens',
                      'Documentos',
                      'Navegar...',
                    ],
                    onChanged: onFolderChanged,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 22),
            onPressed: () {},
            tooltip: 'Configurações',
            color: Colors.black54,
          ),
        ],
      ),
    );
  }
}

class _SelectorButton extends StatelessWidget {
  final String prefix;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _SelectorButton({
    required this.prefix,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      initialValue: value,
      onSelected: onChanged,
      itemBuilder: (_) =>
          options.map((o) => PopupMenuItem(value: o, child: Text(o))).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
          color: Colors.grey.shade50,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$prefix ',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_drop_down, size: 16, color: Colors.black54),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter tabs
// ---------------------------------------------------------------------------

class _FilterTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _FilterTabs({required this.selectedIndex, required this.onChanged});

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
    return SizedBox(
      height: 40,
      child: ColoredBox(
        color: Colors.white,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(_tabs.length, (i) {
              final selected = i == selectedIndex;
              return InkWell(
                onTap: () => onChanged(i),
                child: Container(
                  height: 40,
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
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Download list item
// ---------------------------------------------------------------------------

class _DownloadListItem extends StatelessWidget {
  final MockDownloadItem item;

  const _DownloadListItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final meta =
        '${item.duration} · ${item.size} · ${item.format} · '
        '${item.resolution} · ${item.fps} · ${item.source}';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D2D),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white54,
                  size: 30,
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
                    const SizedBox(height: 4),
                    Text(
                      meta,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Status bar
// ---------------------------------------------------------------------------

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
              side: const BorderSide(color: Colors.white70),
            ),
            child: const Text('Configurar motor'),
          ),
        ],
      ),
    );
  }
}
